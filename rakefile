require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

PKG_NAME      = 'javaobs'
PKG_VERSION   = '0.3.1'
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"
RUBY_FORGE_PROJECT = "javaobs"
RUBY_FORGE_USER    = "wsobel"

desc "Default Task"
task :default => [ :test ]

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir.glob( "test/test.rb" )
  t.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Java Objects"
  rdoc.main = 'README.rdoc'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
end
  
dist_dirs = [ "lib", "test", "examples" ]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "Decode Java Serialized Objects to Ruby Objects."
  s.description = %q{Takes Java serialized objects in a file or stream and creates Ruby wrapper objects and decodes. The package can also write Java objects once UUID is read from sample.}

  s.author = "William Sobel"
  s.email = "willsobel@mac.com"
  s.rubyforge_project = "javaobj"
  s.homepage = "http://www.rubyforge.org"

  s.has_rdoc = true
  s.requirements << 'none'

  s.require_path = 'lib'

  s.files = [ "rakefile", "install.rb" ]
  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end
end
  
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

task :release => [:repackage] do
  files = ["gem", "zip", "tgz"].map { |ext| "pkg/#{PKG_FILE_NAME}.#{ext}" }
  
  if RUBY_FORGE_PROJECT then
    require 'net/http'
    require 'open-uri'

    project_uri = "http://rubyforge.org/projects/#{RUBY_FORGE_PROJECT}/"
    project_data = open(project_uri) { |data| data.read }
    puts project_data
    group_id = project_data[/[?&]group_id=(\d+)/, 1]
    raise "Couldn't get group id" unless group_id

    # This echos password to shell which is a bit sucky
    if ENV["RUBY_FORGE_PASSWORD"]
      password = ENV["RUBY_FORGE_PASSWORD"]
    else
      print "#{RUBY_FORGE_USER}@rubyforge.org's password: "
      password = STDIN.gets.chomp
    end
    
    login_response = Net::HTTP.post_form(URI.parse('http://rubyforge.org/account/login.php'),
                               {'form_loginname'=> RUBY_FORGE_USER, 
                                'form_pw'=> password, 'login' => 1})

    cookie = login_response["set-cookie"]
    raise "Login failed" unless cookie
    headers = { "Cookie" => cookie }

    release_uri = "http://rubyforge.org/frs/admin/?group_id=#{group_id}"
    release_data = open(release_uri, headers) { |data| data.read }
    package_id = release_data[/[?&]package_id=(\d+)/, 1]
    raise "Couldn't get package id" unless package_id

    first_file = true
    release_id = ""

    
    files.each do |filename|
      basename  = File.basename(filename)
      file_ext  = File.extname(filename)
      file_data = File.open(filename, "rb") { |file| file.read }

      puts "Releasing #{basename}..."

      release_response = Net::HTTP.start("rubyforge.org", 80) do |http|
        release_date = Time.now.strftime("%Y-%m-%d %H:%M")
        type_map = {
          ".zip"    => "3000",
          ".tgz"    => "3110",
          ".gz"     => "3110",
          ".gem"    => "1400"
        }; type_map.default = "9999"
        type = type_map[file_ext]
        boundary = "rubyqMY6QN9bp6e4kS21H4y0zxcvoor"

        query_hash = if first_file then
          {
            "group_id" => group_id,
            "package_id" => package_id,
            "release_name" => RELEASE_NAME,
            "release_date" => release_date,
            "type_id" => type,
            "processor_id" => "8000", # Any
            "release_notes" => "",
            "release_changes" => "",
            "preformatted" => "1",
            "submit" => "1"
          }
        else
          {
            "group_id" => group_id,
            "release_id" => release_id,
            "package_id" => package_id,
            "step2" => "1",
            "type_id" => type,
            "processor_id" => "8000", # Any
            "submit" => "Add This File"
          }
        end

        query = "?" + query_hash.map do |(name, value)|
          [name, URI.encode(value)].join("=")
        end.join("&")

        data = [
          "--" + boundary,
          "Content-Disposition: form-data; name=\"userfile\"; filename=\"#{basename}\"",
          "Content-Type: application/octet-stream",
          "Content-Transfer-Encoding: binary",
          "", file_data, ""
          ].join("\x0D\x0A")

        release_headers = headers.merge(
          "Content-Type" => "multipart/form-data; boundary=#{boundary}"
        )

        target = first_file ? "/frs/admin/qrs.php" : "/frs/admin/editrelease.php"
        http.post(target + query, data, release_headers)
      end

      if first_file then
        release_id = release_response.body[/release_id=(\d+)/, 1]
        raise("Couldn't get release id") unless release_id
      end

      first_file = false
    end
  end
end
