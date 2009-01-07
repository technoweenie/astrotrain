namespace :app do
  desc "Start astrotrain DRb server."
  task :server => :merb_env do
    pid_filename = Merb.root / 'log' / 'astrotrain_job.pid'
    begin
      File.open(pid_filename, 'w') { |f| f << Process.pid.to_s }
      SLEEP = 5
       
      trap('TERM') { puts 'Exiting...'; $exit = true }
      trap('INT')  { puts 'Exiting...'; $exit = true }

      loop do
        count = nil

        realtime = Benchmark.realtime do
          files = Dir[Merb.root / "queue" / "*"]
          files.each do |mail|
            Message.receive_file(mail)
          end
          count = files.size
        end

        break if $exit

        if count.zero? 
          sleep(SLEEP)
        else
          status = "#{count} mails processed at %.4f m/s ..." % [count / realtime]
          Merb.logger.info status
        end
      
        break if $exit
      end
    ensure
      FileUtils.rm(pid_filename) rescue nil
    end
  end
end