require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "astrotrain"
    gem.summary = %Q{email => http post}
    gem.email = "technoweenie@gmail.com"
    gem.homepage = "http://github.com/entp/astrotrain"
    gem.authors = ["technoweenie"]

    dm_ver = "0.9.11"
    gem.add_runtime_dependency 'addressable',   '2.0.2'
    gem.add_runtime_dependency "tmail",         "1.2.3.1"
    gem.add_runtime_dependency "dm-core",        dm_ver # The datamapper ORM
    gem.add_runtime_dependency "dm-aggregates",  dm_ver # Provides your DM models with count, sum, avg, min, max, etc.
    gem.add_runtime_dependency "dm-timestamps",  dm_ver # Automatically populate created_at, created_on, etc. when those properties are present.
    gem.add_runtime_dependency "dm-types",       dm_ver # Provides additional types, including csv, json, yaml.
    gem.add_runtime_dependency "dm-validations", dm_ver # Validation framework
    gem.add_development_dependency "context"
    gem.add_development_dependency "rr"
    gem.add_development_dependency "sinatra"
    gem.add_development_dependency "xmppr4-simple"
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

namespace :at do
  task :init do
    $LOAD_PATH.unshift File.expand_path(ENV['LIB']) if ENV['LIB']
    require ENV['CONFIG'] if ENV['CONFIG']

    if !Object.const_defined?(:Astrotrain)
      require 'astrotrain'
      Astrotrain.load
    end

    Astrotrain::Message.queue_path = ENV['QUEUE'] if ENV['QUEUE']
    if !File.exist?(Astrotrain::Message.queue_path)
      puts "No Queue: #{Astrotrain.queue_path.inspect}"
      exit
    end
  end

  desc "List Mappings"
  task :mappings => :init do
    Astrotrain::Mapping.all.each do |map|
      puts "##{map.id}: #{map.full_email} => #{map.destination}"
      puts "Separated by: #{map.separator.inspect}" if !map.separator.blank?
      puts
    end
  end

  desc "Add mapping EMAIL=ticket*@foo.com DEST=http://foo.com/email [TRANS=(http_post|jabber)] [SEP=REPLYABOVEHERE] [HEADERS=delivered_to,to,original_to]"
  task :map => :init do
    map = Astrotrain::Mapping.new
    map.email_user, map.email_domain = ENV['EMAIL'].to_s.split('@')
    map.destination = ENV['DEST']
    map.transport   = ENV['TRANS'] if ENV['TRANS']
    map.separator   = ENV['SEP']   if ENV['SEP']
    if map.save
      puts "Mapping created for #{map.full_email} => #{map.destination}"
      Rake::Task['at:mappings'].invoke
    else
      puts map.inspect
      puts map.errors.inspect
    end
  end

  desc "Remove mapping MAP=123"
  task :unmap => :init do
    map = Astrotrain::Mapping.get(ENV["MAP"])
    map.destroy if map
    Rake::Task['at:mappings'].invoke
  end

  desc "Start astrotrain DRb server."
  task :process => :init do
    require 'astrotrain/worker'
    Astrotrain::Worker.start
  end
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "astrotrain #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


desc 'Default: run test examples'
task :default => 'test'