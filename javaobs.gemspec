# -*- encoding: utf-8 -*-

dist_dirs = [ "lib", "test", "examples" ]

PKG_NAME      = 'javaobs'
PKG_VERSION   = '0.3.2'
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = PKG_NAME
  s.version     = PKG_VERSION
  s.summary     = "Decode Java Serialized Objects to Ruby Objects."
  s.description = %q{Takes Java serialized objects in a file or stream and creates Ruby wrapper objects and decodes. The package can also write Java objects once UUID is read from sample.}

  s.author      = "William Sobel"
  s.email       = "willsobel@mac.com"
  s.rubyforge_project = "javaobj"
  s.homepage    = "http://www.rubyforge.org"

  s.has_rdoc    = true
  s.requirements << 'none'

  s.require_path = 'lib'

  s.files       = [ "Rakefile", "install.rb" ]
  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end
end
