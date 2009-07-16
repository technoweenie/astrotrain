require 'net/imap'
require 'stringio'
require 'ostruct'

module Astrotrain
  class Imap
    class << self
      attr_accessor :connection_class
    end
    self.connection_class = Net::IMAP

    attr_reader :host
    attr_reader :options

    # :host, :port, :use_ssl, :user, :password
    def initialize(host, options = {})
      @host    = host
      @options = options
    end

    def connection
      if @connection.nil? || @connection.disconnected?
        @connection = self.class.connection_class.new(@host, @options[:port], @options[:use_ssl])
        @connection.login @options[:user], @options[:password]
      end
      @connection
    end

    def close
      if @connection && !@connection.disconnected?
        @connection.logout
        @connection.disconnect
      end
    end

    def mailboxes(refname = '', mailbox = '*')
      mailboxes = []
      connection.list(refname, mailbox).each do |m|
        mailboxes << Mailbox.new(self, m.name)
      end
      mailboxes
    end

    def ==(other)
      other.class == self.class && other.host == @host && other.options == @options
    end

    def inspect
      %(#<Astrotrain::Imap @host=#{@host}#{":#{@options[:port]}" if @options[:port]}>)
    end

    class Mailbox
      attr_reader :name
      attr_reader :connection

      def initialize(imap, name)
        @connection = imap.connection
        @name       = name
      end

      def with
        @connection.select @name
        retval = yield
        @connection.close
        retval
      end

      def search(q = 'ALL', options = {})
        options[:limit]  ||= 15
        search_for_ids(q.to_s.split(" ")) do |ids|
          ids = ids[0..options[:limit]-1] if ids.size > options[:limit]
          Message.fetch(@connection, ids, options[:fields])
        end
      end

      def move(messages, destination)
        return if messages.empty?
        messages = messages.map { |m| m.number } if messages.first.respond_to?(:number)
        @connection.copy messages, destination.name
        destroy_messages messages
      end

      def destroy
        @connection.delete @name
      end

      def destroy_messages(messages)
        return if messages.empty?
        messages = messages.map { |m| m.number } if messages.first.respond_to?(:number)
        @connection.store messages, "+FLAGS", [:Deleted]
      end

      def ==(other)
        other.class == self.class && @connection == other.connection && @name == other.name
      end

      def inspect
        %(#<Astrotrain::Imap::Mailbox @name=#{@name}>)
      end

    protected
      def search_for_ids(*args)
        args = %w(ALL) if args.empty?
        with do
          ids = @connection.search(*args)
          block_given? ? yield(ids) : ids
        end
      end
    end

    class Message
      class << self
        attr_accessor :raw_field
        def fetch(connection, ids, fields)
          fields = process_fields(fields)
          connection.fetch(ids, fields).map! { |m| Message.new(m, fields) }
        end

        def process_fields(fields)
          fields = [fields]
          fields.uniq!
          fields.compact!
          fields << raw_field if fields.empty?
          fields
        end
      end

      self.raw_field = 'RFC822'

      attr_reader :data, :fields, :number, :raw

      def initialize(data, fields = nil)
        @data   = data
        @fields = fields || []
        @number = data.seqno
        if @fields.include?(self.class.raw_field)
          @raw = self[self.class.raw_field]
        end
      end

      def [](key)
        @data.attr[key]
      end

      def ==(other)
        @number == other.number
      end

      def inspect
        %(#<Astrotrain::Imap::Message @number=#{@number}>)
      end
    end

    class MockConnection
      attr_reader :host
      attr_reader :port
      attr_reader :use_ssl
      attr_reader :trace

      def initialize(host, port, use_ssl)
        @host    = host
        @port    = port
        @use_ssl = use_ssl
        clear
        close
      end

      def login(*args)
        write_trace :login, *args
      end

      def list(*args)
        write_trace :list, *args
      end

      def select(*args)
        write_trace :select, *args
      end

      def delete(*args)
        write_trace :delete, *args
      end

      def store(*args)
        write_trace :store, *args
      end

      def copy(*args)
        write_trace :copy, *args
      end

      def search(*args)
        write_trace :search, *args
      end

      def fetch(*args)
        write_trace :fetch, *args
      end

      def disconnected?
        @disconnected == true
      end

      def close
        @disconnected = true
      end

      # TESTER API
      def mock(method, *args, &block)
        @mocks[[method, args]] = block
      end

      def clear
        @mocks = {}
        @trace = []
      end

    protected
      def write_trace(method, *args)
        @disconnected = false
        @trace << "#{method}(#{args.inspect})"
        if mock = @mocks[[method.to_sym, args]]
          mock.call
        end
      end
    end
  end
end