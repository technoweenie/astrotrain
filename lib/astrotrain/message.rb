require 'digest/sha1'
require 'fileutils'
require 'tempfile'
require 'set'

module Astrotrain
  # Wrapper around a TMail object
  class Message
    attr_accessor :body
    attr_reader :mail

    class << self
      attr_reader   :queue_path, :archive_path
      attr_accessor :recipient_header_order, :skipped_headers
    end

    def self.queue_path=(path)
      if path
        path = File.expand_path(path)
        FileUtils.mkdir_p path
      end
      @queue_path = path
    end

    def self.archive_path=(path)
      if path
        path = File.expand_path(path)
        FileUtils.mkdir_p path
      end
      @archive_path = path
    end

    self.skipped_headers        = Set.new %w(date from subject delivered-to x-original-to received)
    self.recipient_header_order = %w(original_to delivered_to to)
    self.queue_path             = File.join(Astrotrain.root, 'queue')

    # Dumps the raw text into the queue_path.  Not really recommended, since you should
    # set the queue_path to the directory your incoming emails are dumped into.
    def self.queue(raw)
      filename = nil
      digest   = Digest::SHA1.hexdigest(raw)
      while filename.nil? || File.exist?(filename)
        filename = File.join(queue_path, Digest::SHA1.hexdigest(digest + rand.to_s))
      end
      File.open filename, 'wb' do |f|
        f.write raw
      end
      filename
    end

    # Parses the given raw email text and processes it with a matching Mapping.
    def self.receive(raw, file = nil)
      message = parse(raw)
      Astrotrain.callback(:pre_mapping, message)
      Mapping.process(message, file)
      message
    rescue Astrotrain::ProcessingCancelled
    end

    # Processes the given file.  It parses it by reading the contents, and optionally
    # archives or removes the original file.
    def self.receive_file(path)
      raw         = IO.read(path)
      logged_path = path
      if archive_path
        daily_archive_path = archive_path / Time.now.year.to_s / Time.now.month.to_s / Time.now.day.to_s
        FileUtils.mkdir_p(daily_archive_path)
        logged_path = daily_archive_path / File.basename(path)
        FileUtils.mv path, logged_path if path != logged_path
      end
      receive(raw, logged_path)
    end

    # Parses the raw email headers into a Astrotrain::Message instance.
    def self.parse(raw)
      new Mail.parse(raw)
    end

    def self.parse_email_addresses(value)
      emails     = value.split(",")
      collection = []
      emails.each do |addr|
        addr.strip!
        next if addr.blank?
        header = parse_email_address(addr.to_s)
        collection << unescape(header[:email]) if !header[:email].blank?
      end
      collection
    end

    def self.parse_email_address(email)
      return {} if email.blank?
      begin
        header = TMail::Address.parse(email)
        parsed = {:name => header.name}
        if header.is_a?(TMail::AddressGroup)
          header = header[0]
        end
        if !header.blank?
          parsed[:email] = header.address
        end
        parsed
      rescue SyntaxError, TMail::SyntaxError
        email = email.scan(/\<([^\>]+)\>/)[0]
        if email.blank?
          return {:name => nil, :email => nil}
        else
          email = email[0]
          retry
        end
      end
    end

    # Stolen from Rack/Camping, remove the "+" => " " translation
    def self.unescape(s)
      s.gsub!(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
      s
    end

    def initialize(mail)
      @mail        = mail
      @mapping     = nil
      @attachments = []
      @recipients  = {}
    end

    # Gets the recipients of an email using the To/Delivered-To/X-Original-To headers.
    # It's not always straightforward which email we want when dealing with filters
    # and forward rules.
    def recipients(order = nil)
      if !@recipients.key?(order)
        order = self.class.recipient_header_order if order.blank?
        recipients = []

        parse_email_headers recipients_from_body, recipients
        order.each do |key|
          parse_email_headers(send("recipients_from_#{key}"), recipients)
        end

        recipients.flatten!
        recipients.uniq!
        @recipients[order] = recipients
      else
        @recipients[order]
      end
    end

    def recipients_from_to
      @recipient_from_to ||= [@mail['to'].to_s]
    end

    def recipients_from_delivered_to
      @recipient_from_delivered_to ||= begin
        delivered = @mail['Delivered-To']
        if delivered.respond_to?(:first)
          delivered.map! { |a| a.to_s }
        else
          [delivered.to_s]
        end
      end
    end

    def recipients_from_original_to
      @recipient_from_original_to ||= [@mail['X-Original-To'].to_s]
    end

    def recipients_from_body
      @recipients_from_body ||= body.scan(/<[\w\.\_\%\+\-]+@[\w\-\_\.]+>/)
    end

    def sender
      @sender ||= TMail::Unquoter.unquote_and_convert_to(@mail['from'].to_s, "utf-8")
    end

    def subject
      @mail.subject
    rescue Iconv::InvalidCharacter
      @mail.quoted_subject
    end

    def message_id
      @message_id ||= header('message-id').to_s.gsub(/^<|>$/, '')
    end

    def body
      @body ||= process_message_body(:body)
    end

    def html
      @html ||= process_message_body(:html)
    end

    def attachments
      @attachments ||= process_message_body(:attachments)
    end

    def raw
      @mail.port.to_s
    end

    def header(key)
      headers[key]
    end

    def headers
      @headers ||= begin
        h = {}
        @mail.header.each do |key, value|
          next if self.class.skipped_headers.include?(key)
          h[key] = read_header(key) 
        end
        h
      end
    end

    class Attachment
      def initialize(part)
        @part    = part
        @is_read = false
      end

      def content_type
        @part.content_type
      end

      def filename
        @filename ||= @part.type_param("name") || @part.disposition_param('filename')
      end

      # For IO API compatibility when used with Rest-Client
      def close
      end

      alias path filename

      def read(value = nil)
        if read?
          nil
        else
          @is_read = true
          data
        end
      end

      def read?
        @is_read == true
      end

      def data
        @part.body
      end

      def attached?
        !filename.nil?
      end

      def ==(other)
        super || (filename == other.filename && content_type == other.content_type)
      end

      def inspect
        %(#<Message::Attachment filename=#{filename.inspect} content_type=#{content_type.inspect}>)
      end
    end

  protected
    def read_header(key)
      header = @mail.header[key]
      begin
        header.to_s
      rescue
        header.raw_body
      end
    end

    def process_message_body(var = nil)
      if @mail.multipart?
        @attachments.clear
        @body, @html = [], []
        scan_parts(@mail)
        @body = @body.join("\n")
        @html = @html.join("\n")
      else
        if @mail.content_type == 'text/html'
          @html = @mail.body
          @body = ''
        else
          @body = @mail.body
          @html = ''
        end
      end
      if !@mail.charset
        @body = convert_to_utf8(@body)
        @html = convert_to_utf8(@html)
      end
      instance_variable_get "@#{var}" if var
    end

    def scan_parts(message)
      message.parts.each do |part|
        if part.multipart?
          scan_parts(part)
        else
          case part.content_type
            when 'text/plain'
              @body << part.body
            when 'text/html'
              @html << part.body
            else
              att = Attachment.new(part)
              @attachments << att if att.attached?
          end
        end
      end
    end

    def parse_email_headers(values, collection)
      values.each do |value|
        if !value.blank?
          collection.push *self.class.parse_email_addresses(value)
        end
      end
    end

    # Attempts to run iconv conversions in common charsets to UTF-8.  Needed for 
    # those crappy emails that don't properly specify a charset in the headers. 
    ICONV_CONVERSIONS = %w(utf-8 ISO-8859-1 ISO-8859-2 ISO-8859-3 ISO-8859-4 ISO-8859-5 ISO-8859-6 ISO-8859-7 ISO-8859-8 ISO-8859-9
      ISO-8859-15 GB2312)
    def convert_to_utf8(s)
      ICONV_CONVERSIONS.each do |from|
        begin
          return Iconv.iconv(ICONV_CONVERSIONS[0], from, s).to_s
        rescue Iconv::IllegalSequence
        ensure
          s
        end
      end
    end
  end
end