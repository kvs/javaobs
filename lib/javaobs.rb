 
require 'delegate'

# Java Objects namespace to read and write Java serialized objects to streams. 
# Any Java serialized object can be read from a stream. To write a Java object,
# the meta class must be primed with a sample input serialized object. The is 
# required because Java uses a UUID to identify classes and it is generated using
# a complex hashing scheme of data and method signatures. Since this system does
# not have access to that information, it needs to get it from a serialized object.
#
# Objects that have custom serialization methods can be read and written by 
# creating a class as we have for the Date class:
#    module Java
#      module Util
#        class Date < SimpleDelegator
#          extend JavaObject
#
#          def initialize
#            super(Time)
#          end
#
#          # Set the time with a Time object.
#          def time=(time)
#            __setobj__(time)
#          end
#
#          def _readJavaData(stream)
#            data = stream.readBlockData
#            t, = data.unpack("Q")
#            __setobj__(Time.at(t / 1000, (t % 1000) * 1000))
#          end
#
#          # Get the data in the form needed for the Java date serialization.
#          def _writeJavaData(stream)
#            t = __getobj__.tv_sec * 1000 + __getobj__.tv_usec / 1000
#            stream.writeBlockData([t].pack("Q"))
#          end
#        end
#      end
#    end
#
# The important methods are the data method that is used for writing the 
# the object to a stream.
#
# All other classes will be auto-generated when the stream is read and persisted. 
# A Java Meta Class is added to the Ruby Class that contains all the Java field
# information needed to serialize the objects. 

module Java
  
  # An error thrown when a serialization error occurs.
  class SerializationError < RuntimeError
  end
  
  # An representation of a Java instance variable used to serialize
  # data to and from a stream.
  class JavaField
    attr_reader :name, :type
    attr_accessor :subtype
    
    # Create a java instance variable with a name and data type.
    def initialize(name, type)
      @name = name
      @type = type
      @subtype = nil
    end
    
    def inspect
      "<JavaField: #{@name}:#{@type.chr}:#{@subtype}>"
    end
  end
  
  # The Java meta class with all the information needed for 
  # serialization of the Ruby class to the stream. This class
  # is attached to the Ruby class.
  class JavaClass
    attr_accessor :superClass, :rubyClass
    attr_reader :name, :uid, :fields, :javaName, :flags, :arrayType
    
    def initialize(name, uid, flags)
      @name = @javaName = name
      ind = name.rindex('.')
      @name = name.slice(ind + 1..name.length) if ind
      @flags = flags
      @uid = uid
      @fields = []
      @arrayType = name[1].bytes.first if name[0] == ?[
    end
      
    # Add a field to the class.
    def addField(field)
      @fields << field
    end
    
    def to_s
      @name
    end
  end
  
  # A small mixin to extend a Ruby class with the associated
  # JavaClass.
  module JavaObject
    def javaClass
      @javaClass
    end
  end
  
  # The custom serialization of the Java Date class
  module Util
    class Date < SimpleDelegator
      extend JavaObject
    
      def initialize
        super(Time)
      end

      # Set the time with a Time object.
      def time=(time)
        __setobj__(time)
      end
    
      def _readJavaData(stream)
        data = stream.readBlockData
        t, = data.unpack("Q")
        __setobj__(Time.at(t / 1000, (t % 1000) * 1000))
      end

      # Get the data in the form needed for the Java date serialization.
      def _writeJavaData(stream)
        t = __getobj__.tv_sec * 1000 + __getobj__.tv_usec / 1000
        stream.writeBlockData([t].pack("Q"))
      end
    end
    
    class HashMap < SimpleDelegator
      extend JavaObject
    
      def initialize
        super(Hash)
        @loadFactor = 0.75
        @threshold = 12
      end

      def _readJavaData(stream)
        # Read loadFactor and threshold.
        stream.defaultReadObject(self)
        stream.readBlockStart
        len = stream.readInt
        size = stream.readInt
        
        h = Hash.new
        size.times do 
          k = stream.readObject
          v = stream.readObject
          h[k] = v
        end
        stream.readBlockEnd
        __setobj__(h)
      end

      def _writeJavaData(stream)
        obj = __getobj__;
        stream.defaultWriteObject(self)
        stream.writeBlockStart(8)
        l = 16
        len = obj.length
        while l < len
          l << 1
        end
        stream.writeInt(l)
        stream.writeInt(len)
        obj.each do |k, v|
          stream.writeObject(k)
          stream.writeObject(v)
        end
        stream.writeBlockEnd
      end      
    end
  end

  # The Java Array wrapper using an Ruby Array.
  class JavaArray < Array
    extend JavaObject
  end

  # Container for the Java serialization constants.
  module ObjectStream
    STREAM_MAGIC = 0xEDAC
    STREAM_VERSION = 5
    
    TC_NULL      = 0x70
    TC_REFERENCE = 0x71
    TC_CLASSDESC = 0x72
    TC_OBJECT    = 0x73
    TC_STRING    = 0x74
    TC_ARRAY     = 0x75
    TC_CLASS     = 0x76
    TC_BLOCKDATA = 0x77
    TC_ENDBLOCKDATA = 0x78
    TC_RESET     = 0x79
    TC_BLOCKDATALONG = 0x7A
    TC_EXCEPTION = 0x7B
    TC_LONGSTRING = 0x7C
    TC_PROXYCLASSDESC = 0x7D
    
    SC_WRITE_METHOD   = 0x01
    SC_SERIALIZABLE   = 0x02
    SC_EXTERNALIZABLE = 0x04
    SC_BLOCKDATA      = 0x08
    
    PRIM_BYTE   = 66 # 'B'
    PRIM_CHAR   = 67 # 'C'
    PRIM_DOUBLE = 68 # 'D'
    PRIM_FLOAT  = 70 # 'F'
    PRIM_INT    = 73 # 'I'
    PRIM_LONG   = 74 # 'J'
    PRIM_SHORT  = 83 # 'S'
    PRIM_BOOL   = 90 # 'Z'
    
    PRIM_ARRAY   = 91 # '['
    PRIM_OBJECT  = 76 # 'L'
  end
  
  # The Ruby version of the Java ObjectInputStream. Creates a Ruby 
  # proxy class for each Java Class.
  class ObjectInputStream
    include ObjectStream
    
    def readByte; @str.read(1).bytes.first; end
    def readBytes(len); @str.read(len); end
    def readUShort; @str.read(2).unpack("S<")[0]; end
    def readShort; @str.read(2).unpack("s>")[0]; end
    def readInt; @str.read(4).unpack("i>")[0]; end
    def readDouble; @str.read(8).unpack("G")[0]; end
    def readFloat; @str.read(4).unpack("g")[0]; end
    def readString; @str.read(readShort); end
    def readBool; @str.read(1).bytes.first != 0; end
    def readUID; @str.read(8); end
    def readLong; @str.read(8).unpack("Q").first; end
  
    # Read the block data beginning tag and return the size. We can have a long or 
    # short block of data.
    def readBlockStart
      byte = readByte
      size = nil
      case byte
      when TC_BLOCKDATA
        size = readByte
        
      when TC_BLOCKDATALONG
        size = readInt
        
      else
        raise SerializationError, "Expecting TC_BLOCKDATA, got #{'0x%X' % byte}" unless byte == TC_BLOCKDATA
      end
      size
    end
    
    # Read the block end tag. Validate it is correct or raise a SerializationError.
    def readBlockEnd
      byte = readByte
      raise SerializationError, "Unexpected byte #{byte}" unless byte == TC_ENDBLOCKDATA
    end
  
    # Read a Java block of data with a size and then the following data.
    def readBlockData
      size = readBlockStart
      data = @str.read(size)
      readBlockEnd
      data
    end
    
    
    # Read all the fields from the stream and add them to the class.
    def readFields(klass)
      fieldCount = readShort
      1.upto(fieldCount) do
        type = readByte
        name = readString
        field = JavaField.new(name, type)
        
        # Check for array and object types
        if type == PRIM_OBJECT || type == PRIM_ARRAY
          field.subtype = readObject
        end
        klass.addField(field)
      end
    end
    
    # Read the class annotation. We do not currently handle annotations.
    def readClassAnnotation
      ebd = readByte
      raise SerializationError, "We do not handle annotations!" unless ebd == TC_ENDBLOCKDATA
    end

    # Gets or creates a corresponding Ruby class for the Java class. This
    # will drop leading com or java and transform the rest of the dotted
    # names to modules.
    def rubyClassFor(name, super_name)
      context = name.split('.')
      f, = context
      context.shift if f == 'java' or f == 'com'
      context.map! { |n| n.capitalize! if n !~ /^[A-Z]/o; n.to_sym }
      kname = context.pop

      mod = Java
      context.each do |m|
        unless mod.constants.include?(m)
          mod = mod.module_eval "#{m} = Module.new"
        else
          mod = mod.const_get(m)
        end
      end
      
      unless mod.constants.include?(kname)
        rclass = mod.module_eval "#{kname} = Class.new(#{super_name})"
      else
        rclass = mod.const_get(kname)
      end
      rclass
    end
    
    # Read the Java class description and create a Ruby class to proxy it 
    # in this name-space. Added special handling for the Date class.
    def readClassDesc
      name = readString
      uid = readUID
      flags = readByte
      klass = JavaClass.new(name, uid, flags)
      
      @objects << klass
      
      readFields(klass)
      readClassAnnotation
      
      klass.superClass = readObject

      # Create Ruby object representing class
      if name =~ /^[A-Z.]+/i
        # Create the class within the correct module.
        rclass = rubyClassFor(name, klass.superClass.to_s)

        unless rclass.methods.index('javaClass')
          rclass.class_eval "extend JavaObject"
        end
        
        rclass.class_eval "@javaClass = klass"
        vars = klass.fields.map do |f|
          ':' + f.name
        end
        rclass.class_eval "attr_accessor #{vars.join(',')}"
        klass.rubyClass = rclass
      else
        # Arrays
        newName = ('JavaArray' + klass.name[1..klass.name.length]).to_sym
        unless Java.constants.index(newName)
          rclass = Java.module_eval "#{newName} = Class.new(JavaArray)"
        else
          rclass = Java.const_get(newName)
        end
        rclass.class_eval "@javaClass = klass"
        klass.rubyClass = rclass
      end
      
      klass
    end

    # Read an array of objects.
    def readArray(klass)
      size = readInt
      a = klass.rubyClass.new
      type = klass.arrayType
      1.upto(size) do
        a << readType(type)
      end
      a
    end

    # Read a primitive data type.
    def readType(type, arrayType = nil, field = nil)
      type = type.bytes.first if type.is_a? String

      case type
      when PRIM_BYTE
        readByte
        
      when PRIM_CHAR
        readByte
        
      when PRIM_DOUBLE
        readDouble
        
      when PRIM_FLOAT
        readFloat
        
      when PRIM_INT
        readInt
        
      when PRIM_LONG
        readLong
        
      when PRIM_SHORT
        readShort
        
      when PRIM_BOOL
        readBool
        
      when PRIM_OBJECT, PRIM_ARRAY
        readObject
        
      else
        raise SerializationError, "Unknown type #{type}"
      end
    end
    
    # Cover method for java method. 
    def defaultReadObject(object)
      readObjectFields(object.class.javaClass, object)
    end

    # Reads the object fields from the stream.
    def readObjectFields(klass, object)
      klass.fields.each do |f|
        v = readType(f.type, f.subtype, f)
        object.send((f.name + '=').intern, v)
      end
    end
    
    # Read class data and recursively read parent classes. If the class
    # is externalizable then we call the _readJavaData method to '
    # perform the custom serialization. See Java::Util::Hash and 
    # Java::Util::Date for an example.
    def readClassData(klass, object = nil)
      if object == nil
        object = klass.rubyClass.new()
        @objects << object
      end
      
      readClassData(klass.superClass, object) if (klass.superClass)
      
      if klass.flags == SC_SERIALIZABLE
        readObjectFields(klass, object)
      else
        object._readJavaData(self)
      end
      
      object
    end
    
    # Read an object from the stream.
    def readObject
      object = nil
      byte = readByte
      case byte
      when TC_OBJECT
        klass = readObject
        object = readClassData(klass)
        
      when TC_REFERENCE
        readShort
        object = @objects[readShort]
        
      when TC_ARRAY
        klass = readObject
        object = readArray(klass)
        @objects << object
        
      when TC_STRING
        object = readString
        @objects << object

      when TC_CLASSDESC
        object = readClassDesc

      when TC_NULL
        object = nil
        
      else
        raise SerializationError, "Unexpected byte #{byte} at #{@str.pos}"
      end

      object
    end

    # Initialize from a stream.
    def initialize(str)
      @str = str
      magic =  readUShort
      streamVersion = readShort
      @objects = []

      raise "Bad stream #{magic.to_s(16)}:#{streamVersion.to_s(16)}" if magic != STREAM_MAGIC ||
      streamVersion != STREAM_VERSION

    end

    # Read all objects in the stream. Calls readObject until the stream
    # eof is reached.
    def readObjects
      objs = []
      until (@str.eof)
        objs << readObject
      end
      objs
    end
  end

  # A Ruby version of the Java ObjectOutputStream. The Ruby classes must 
  # have attached Java meta classes to attach UUID.
  class ObjectOutputStream
    include ObjectStream

    def writeByte(b); @str.putc b; end
    def writeUShort(s); @str.write [s].pack("n"); end
    def writeShort(s); @str.write [s].pack("s"); end
    def writeInt(i); @str.write [i].pack("i"); end
    def writeDouble(d); @str.write [d].pack("G"); end
    def writeFloat(f); @str.write [f].pack("g"); end
    def writeString(s); writeShort(s.length); @str.write s; end
    def writeBool(b); writeByte(b ? 1 : 0); end
    def writeUID(u); @str.write u; end
    def writeLong(l); @str.write [l].pack("Q"); end

    # Creates object reference handles.
    def nextHandle
      h = @nextHandle
      @nextHandle += 1
      h
    end

    # Write an array of objects.
    def writeArray(klass, v)
      type = klass.arrayType
      writeInt(v.length)
      v.each do |e|
        writeType(type, e)
      end
    end
    
    # Write the beginning of a block tag with the size of the block.
    def writeBlockStart(size)
      if (size <= 255)
        writeByte(TC_BLOCKDATA)
        writeByte(size)
      else
        writeByte(TC_BLOCKDATALONG)
        writeInt(size)
      end
    end
    
    # Write the block end tag.
    def writeBlockEnd
      writeByte(TC_ENDBLOCKDATA)
    end

    # Writes a block of data to the stream.
    def writeBlockData(data)
      writeBlockStart(data.length)
      @str.write data
      writeBlockEnd
    end

    # Reads a Java primitive type.
    def writeType(type, v)
      case type
      when PRIM_BYTE
        writeByte(v)

      when PRIM_CHAR
        writeByte(v)

      when PRIM_DOUBLE
        writeDouble(v)

      when PRIM_FLOAT
        writeFloat(v)

      when PRIM_INT
        writeInt(v)

      when PRIM_LONG
        writeLong(v)

      when PRIM_SHORT
        writeShort(v)

      when PRIM_BOOL
        writeBool(v)

      when PRIM_OBJECT, PRIM_ARRAY
        writeObject(v)

      else
        raise SerializationError, "Unknown type #{type}"
      end
    end
    
    # Writes the class description to the stream.
    def writeClassDesc(klass)
      @handles[klass] = nextHandle

      writeString klass.javaName
      writeUID klass.uid
      writeByte klass.flags

      writeShort(klass.fields.length)
      klass.fields.each do |f|
        writeByte(f.type)
        writeString(f.name)
        writeObject(f.subtype) if f.subtype
      end

      writeByte(TC_ENDBLOCKDATA) # Annotations
      writeObject(klass.superClass)
    end
    
    # Ruby version of the default write object method.
    def defaultWriteObject(object)
      writeObjectFields(object.class.javaClass, object)
    end
    
    # Internal method to write meta fields to stream.
    def writeObjectFields(klass, object)
      klass.fields.each do |f|
        v = object.send(f.name.intern)
        writeType(f.type, v)
      end
    end

    # Write the object and class to the stream.
    def writeObjectData(klass, obj)
      writeObjectData(klass.superClass, obj) if klass.superClass

      if klass.flags == SC_SERIALIZABLE
        writeObjectFields(klass, obj)
      else
        obj._writeJavaData(self)
      end
    end
   
    # Writes the object and class data to the stream. Will 
    # write a reference if the object has already been written 
    # once.
    def writeObject(obj)
     unless obj
       writeByte(TC_NULL)
     else
       handle = @handles[obj]
       if (handle)
         writeByte(TC_REFERENCE)
         writeShort(0x007E)
         writeShort(handle)
       else
         case obj
         when JavaClass
           writeByte(TC_CLASSDESC)
           writeClassDesc(obj)

         when JavaArray
           writeByte(TC_ARRAY)
           writeObject(obj.class.javaClass)
           writeArray(obj.class.javaClass, obj)
           @handles[obj] = nextHandle
       
         when String
           writeByte(TC_STRING)
           writeString(obj)
           @handles[obj] = nextHandle
       
         else
           writeByte(TC_OBJECT)
           klass = obj.class.javaClass
           writeObject(klass)
           @handles[obj] = nextHandle
           writeObjectData(klass, obj)
         end
       end
     end
    end

    # Write an array of objects to the stream.
    def writeObjects(objs)
      objs.each do |o|
        writeObject o
      end
    end

    # Create an o writer on with a stream.
    def initialize(str)
      @str = str
      @handles = {}
      @nextHandle = 0

      writeUShort(STREAM_MAGIC)
      writeShort(STREAM_VERSION)
    end
  end
end

