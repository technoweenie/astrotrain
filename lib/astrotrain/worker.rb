require 'benchmark'
module Astrotrain
  class Worker
    attr_accessor :logger, :sleep_duration, :name

    def self.start(options = {}, &block)
      new(options).run(&block)
    end

    def initialize(options = {})
      @name            = options[:name]  || "pid:#{Process.pid}"
      @pid             = options[:pid]   || File.join(Astrotrain.root, 'log', 'astrotrain_job.pid')
      @sleep_duration  = options[:sleep] || 5
      @logger          = options.key?(:logger) ? options[:logger] : STDOUT
    end

    # override this to perform other tasks in the astrotrain job loop
    def run(&block)
      block ||= lambda { |w| w.process_emails }
      setup(&block)
    end

    def process_emails
      files = 0
      Dir.foreach(Message.queue_path) do |f|
        next if f =~ /^\.{1,2}$/
        files += 1
        file = File.join(Message.queue_path, f)
        Message.receive_file(file)
      end
      files
    end

    def say(s)
      @logger << "#{s}\n" if @logger
    end

    def setup
      say "*** Starting Astrotrain::Worker #{@name}"
      FileUtils.mkdir_p File.dirname(@pid)

      File.open(@pid, 'w') { |f| f << Process.pid.to_s }
       
      trap('TERM') { puts 'Exiting...'; $exit = true }
      trap('INT')  { puts 'Exiting...'; $exit = true }

      loop do
        count    = nil
        realtime = Benchmark.realtime { count = yield(self) }

        break if $exit

        if count.zero?
          sleep(@sleep_duration)
        else
          puts "#{count} mails processed at %.4f m/s ..." % [count / realtime]
        end

        break if $exit
      end
    ensure
      FileUtils.rm(@pid) rescue nil
    end
  end
end