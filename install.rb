require 'rbconfig'
require 'find'
require 'ftools'

include Config

$ruby = CONFIG['ruby_install_name']

$sitedir = CONFIG["sitelibdir"]
unless $sitedir
  version = CONFIG["MAJOR"]+"."+CONFIG["MINOR"]
  $libdir = File.join(CONFIG["libdir"], "ruby", version)
  $sitedir = $:.find {|x| x =~ /site_ruby/}
  if !$sitedir
    $sitedir = File.join($libdir, "site_ruby")
  elsif $sitedir !~ Regexp.quote(version)
    $sitedir = File.join($sitedir, version)
  end
end

if (destdir = ENV['DESTDIR'])
  $sitedir = destdir + $sitedir
  File::makedirs($sitedir)
end

rake_dest = File.join($sitedir, "rake")
File::makedirs(rake_dest, true)
File::chmod(0755, rake_dest)

# The library files

files = Dir.chdir('lib') { Dir['**/*.rb'] }

for fn in files
  fn_dir = File.dirname(fn)
  target_dir = File.join($sitedir, fn_dir)
  if ! File.exist?(target_dir)
    File.makedirs(target_dir)
  end
  File::install(File.join('lib', fn), File.join($sitedir, fn), 0644, true)
end

