require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc 'Default: run test examples'
task :default => 'test'

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
    pid_filename = File.join(Astrotrain.root, 'log', 'astrotrain_job.pid')

    FileUtils.mkdir_p File.dirname(pid_filename)
    require 'benchmark'

    begin
      File.open(pid_filename, 'w') { |f| f << Process.pid.to_s }
      SLEEP = 5
       
      trap('TERM') { puts 'Exiting...'; $exit = true }
      trap('INT')  { puts 'Exiting...'; $exit = true }

      loop do
        count = nil

        realtime = Benchmark.realtime do
          files = Dir["#{Astrotrain::Message.queue_path}/*"]
          files.each do |mail|
            Astrotrain::Message.receive_file(mail)
          end
          count = files.size
        end

        break if $exit

        if count.zero?
          sleep(SLEEP)
        else
          puts "#{count} mails processed at %.4f m/s ..." % [count / realtime]
        end
      
        break if $exit
      end
    ensure
      FileUtils.rm(pid_filename) rescue nil
    end
  end
end