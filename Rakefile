require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "astrotrain"
    gem.summary = %Q{email => http post}
    gem.email = "technoweenie@gmail.com"
    gem.homepage = "http://github.com/entp/astrotrain"
    gem.authors = ["technoweenie"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
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