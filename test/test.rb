
$testdir  = File.dirname(__FILE__)
$: << "#{$testdir}/../lib"

require 'javaobs'
require 'test/unit'

class JavaTest < Test::Unit::TestCase

  def setup
    system("javac #{$testdir}/Test.java")
    system("java -classpath #{$testdir} Test")
    system("javac #{$testdir}/Test2.java")
    system("java -classpath #{$testdir} Test2")
  end
  
  def teardown
    File.unlink('t.tmp') rescue nil
    File.unlink('t2.tmp') rescue nil
    File.unlink('t.tmp.new') rescue nil
    File.unlink("#{$testdir}/Test.class") rescue nil
    File.unlink("#{$testdir}/Test2.class") rescue nil    
  end
  
  def test_read
    orig = ''
    objs = nil
    File.open("t.tmp") do |f|
      f.binmode
      
      orig = f.read
      f.seek(0)
      
      os = Java::ObjectInputStream.new(f)
      assert os
      objs = os.readObjects
      assert objs
    end

    obj1, obj2 = objs
    assert_equal obj1.a, 1
    assert_equal obj1.b, 2
    assert_equal obj1.c, 1000000000000000
    assert_equal obj1.d, "Hello"
    obj1.e.each_with_index { |v, i| assert_equal v, i }
    assert_kind_of Java::Util::Date, obj1.date
    assert_equal obj1.date, Time.local(2006, 06, 05, 13, 20, 0)
    
    assert_equal obj2.class, Java::Util::Date
  end
  
  def test_read_map
    orig = ''
    objs = nil
    File.open("t2.tmp") do |f|
      f.binmode
      
      orig = f.read
      f.seek(0)
      
      os = Java::ObjectInputStream.new(f)
      assert os
      objs = os.readObjects
      assert objs
    end

    obj1, = objs
    map = obj1.map
    assert_equal ["Five", "Four", "One", "Seven", "Six", "Three", "Two"], map.keys.sort
    {"One" => 1, "Two" => 2, "Three" => 3, "Four" => 4, 
      "Five" => 5, "Six" => 6, "Seven" => 7}.each do |k, v|
        assert_equal v, map[k].value
    end
  end

  def test_write
        orig = ''
    objs = nil
    File.open("t.tmp") do |f|
      f.binmode
      
      orig = f.read
      f.seek(0)
      
      os = Java::ObjectInputStream.new(f)
      assert os
      objs = os.readObjects
      assert objs
    end
    
    File.open('t.tmp.new', 'w') do |f|
      f.binmode
      
      os = Java::ObjectOutputStream.new(f)
      os.writeObjects(objs)
    end
    
    mine = File.open('t.tmp.new').read
    assert_equal mine, orig
  end
end
    

if $0 == __FILE__
    suite = Test::Unit::TestSuite.new('DataSource')
    ObjectSpace.each_object(Class) do |klass|
        suite << klass.suite if (Test::Unit::TestCase > klass)
    end
    require 'test/unit/ui/console/testrunner'
    Test::Unit::UI::Console::TestRunner.run(suite).passed?
end
