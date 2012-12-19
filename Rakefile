require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

desc "Default Task"
task :default => [ :test ]

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir.glob( "test/test.rb" )
  t.verbose = true
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Java Objects"
  rdoc.main = 'README.rdoc'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
end
