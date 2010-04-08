require 'set'

module Astrotrain
  # Wrapper around a TMail object
  class Message
    # Attempts to run iconv conversions in common charsets to UTF-8.  Needed for 
    # those crappy emails that don't properly specify a charset in the headers. 
    ICONV_CONVERSIONS = %w(utf-8 ISO-8859-1 ISO-8859-2 ISO-8859-3 ISO-8859-4 ISO-8859-5 ISO-8859-6 ISO-8859-7 ISO-8859-8 ISO-8859-9
      ISO-8859-15 GB2312)

    # Reference to the TMail::Mail object that parsed the raw email.
    attr_reader :mail

    class << self
      attr_accessor :recipient_header_order, :skipped_headers
    end

    # Astrotrain::Message#headers does not show these headers
    self.skipped_headers        = Set.new %w(date from subject delivered-to x-original-to received)

    # This is the default order that Astrotrain will search for a matching recipient.
    self.recipient_header_order = %w(original_to delivered_to to)

    # Parses the raw email headers into a Astrotrain::Message instance.
    #
    # raw - String of the email content
    #
    # Returns Astrotrain::Mail instance.
    def self.parse(raw)
      new Mail.parse(raw)
    end

    # Parses a comma separated list of emails.
    #
    #   parse_email_addresses("foo <foo@example.com>, bar@example.com")
    #     # => [ "foo@example.com", "bar@example.com" ]
    #
    # value - String list of email addresses
    #
    # Returns Array of email addresses.
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

    # Parses a single email and splits out the name and actual email address.
    #
    #   parse_email_address("foo <foo@example.com>")
    #     # => {:email => "foo@example.com", :name => 'foo'}
    #
    # email - String of the address to parse
    #
    # Returns Hash with :email and :name keys.
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
      @body = @html = @attachments = nil
      @mail        = mail
      @recipients  = {}
    end

    # Gets the recipients of an email using the To/Delivered-To/X-Original-To 
    # headers.  It's not always straightforward which email we want when 
    # dealing with filters and forward rules.
    #
    # order - Array of email header names that specifies the order that the 
    #         list of recipient emails is assembled.  Valid strings are: 
    #         'original_to', 'delivered_to', and 'to'.
    #
    # Returns Array of possible recipients.
    def recipients(order = nil)
      if !@recipients.key?(order)
        order = self.class.recipient_header_order if order.blank?
        recipients = []

        order.each do |key|
          parse_email_headers(send("recipients_from_#{key}"), recipients)
        end
        parse_email_headers recipients_from_body, recipients

        recipients.flatten!
        recipients.uniq!
        @recipients[order] = recipients
      else
        @recipients[order]
      end
    end

    # Returns Array of full email addresses from the TO header.
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_to
      @recipient_from_to ||= [@mail['to'].to_s]
    end

    # Returns Array of full email addresses from the Delivered-To header.
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_delivered_to
      @recipient_from_delivered_to ||= begin
        arr = @mail['Delivered-To']
        arr ? arr.map { |a| a.to_s } : []
      end
    end

    # Returns Array of full email addresses from the X-Original-To header.
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_original_to
      @recipient_from_original_to ||= [@mail['X-Original-To'].to_s]
    end

    # Parses out all email addresses from the body of the email.
    #
    # Returns Array of full email addresses from the email body
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_body
      @recipients_from_body ||= body.scan(/<[\w\.\_\%\+\-]+@[\w\-\_\.]+>/)
    end

    # Unquotes and converts the From header to UTF-8.
    #
    # Returns String
    def sender
      @sender ||= TMail::Unquoter.unquote_and_convert_to(@mail['from'].to_s, "utf-8")
    end

    # Unquotes and converts the Subject header to UTF-8.
    #
    # Returns String
    def subject
      @mail.subject
    rescue Iconv::InvalidCharacter
      @mail.quoted_subject
    end

    # Gets the unique message-id for the email, with the surrounding < and > 
    # parsed out.
    #
    # Returns String
    def message_id
      @message_id ||= headers['message-id'].to_s.gsub(/^<|>$/, '')
    end

    # Gets the plain/text body of the email.
    #
    # Returns String
    def body
      process_message_body if @body
      @body
    end

    # Gets the html body of the email.
    #
    # Returns String
    def html
      process_message_body if @html
      @html
    end

    # 
    def attachments
      process_message_body if @attachments
      @attachments
    end

    # Gets the original email data.
    #
    # Returns String
    def raw
      @mail.port.to_s
    end

    # Builds a hash of headers, skipping the keys specified in
    # #skipped_headers.  If header values cannot be parsed, the original
    # raw value is provided.
    #
    # Returns Hash of the headers with String keys and values.
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

  protected
    # Reads a header from the key and attempts to parse it.  If parsing
    # fails, the raw header body is sent.
    #
    # key - String header key
    #
    # Returns the parsed String header value.
    def read_header(key)
      header = @mail.header[key]
      begin
        header.to_s
      rescue
        header.raw_body
      end
    end

    # Parses the mail's parts, assembling the plain/HTML Strings, as well as
    # any attachments.
    #
    # Returns nothing.
    def process_message_body
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
    end

    # Recursive method to scan all the parts of the given part.
    #
    # Returns nothing.
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

    # Parses the given array of values and adds them to the collection.
    #
    # values     - Array of full email addresses: ["foo <foo@bar.com>", "bar@bar.com"]
    # collection - Array of accumulated email addresses after going through
    #              Astrotrain::Mail.parse_email_addresses: ["foo@bar.com", "bar@bar.com"]
    #
    # Returns the collection Array.
    def parse_email_headers(values, collection)
      values.each do |value|
        if !value.blank?
          collection.push *self.class.parse_email_addresses(value)
        end
      end
      collection
    end

    # Converts a given String to utf-8 by trying various character sets.  TMail
    # does this automatically, so it is only needed if no charset is set.
    #
    # s - unconverted String in the wrong character set
    #
    # Returns converted String.
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