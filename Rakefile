require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc 'Default: run test examples'
task :default => 'test'

namespace :at do
  desc "Start astrotrain DRb server."
  task :process do
    if ENV['LIB']
      $LOAD_PATH.unshift File.expand_path(ENV['LIB'])
    end
    if ENV['CONFIG']
      require ENV['CONFIG']
    end

    if !Object.const_defined?(:Astrotrain)
      require 'astrotrain'
      Astrotrain.load
    end

    ENV['QUEUE'] ||= File.join(Astrotrain.root, 'queue')

    pid_filename = File.join(Astrotrain.root, 'log', 'astrotrain_job.pid')

    if !File.exist?(ENV['QUEUE'])
      puts "No Queue: #{ENV['QUEUE'].inspect}"
      exit
    end

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
          files = Dir["#{ENV['QUEUE']}/*"]
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