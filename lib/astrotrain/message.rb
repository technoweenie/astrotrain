require 'mail'
require 'set'

module Astrotrain
  # Wrapper around a TMail object
  class Message
    # Attempts to run iconv conversions in common charsets to UTF-8.  Needed for 
    # those crappy emails that don't properly specify a charset in the headers. 
    ICONV_CONVERSIONS = %w(utf-8 ISO-8859-1 ISO-8859-2 ISO-8859-3 ISO-8859-4 ISO-8859-5 ISO-8859-6 ISO-8859-7 ISO-8859-8 ISO-8859-9
      ISO-8859-15 GB2312)

    EMAIL_REGEX = /[\w\.\_\%\+\-]+@[\w\-\_\.]+/

    # Reference to the TMail::Mail object that parsed the raw email.
    attr_reader :mail

    class << self
      attr_accessor :recipient_header_order, :skipped_headers
    end

    # Astrotrain::Message#headers does not show these headers
    self.skipped_headers        = Set.new %w(to cc from subject delivered-to x-original-to received)

    # This is the default order that Astrotrain will search for a matching recipient.
    self.recipient_header_order = %w(original_to delivered_to to)

    # Parses the raw email headers into a Astrotrain::Message instance.
    #
    # raw - String path to the file.
    #
    # Returns Astrotrain::Message instance.
    def self.read(raw)
      new ::Mail.read(raw)
    end

    # Parses the raw email headers into a Astrotrain::Message instance.
    #
    # raw - String of the email content
    #
    # Returns Astrotrain::Message instance.
    def self.parse(raw)
      new ::Mail.new(raw)
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
        order.push :body
        recipients = []

        emails = order.inject([]) do |memo, key|
          memo.push *send("recipients_from_#{key}")
        end

        @recipients[order] = self.class.parse_email_addresses(emails)
      end
      @recipients[order]
    end

    # Unquotes and converts the From header to UTF-8.
    #
    # Returns String
    def from
      @from ||= unquoted_address_header(:from)
    end
    alias sender from

    # Unquotes and converts the To header to UTF-8.
    #
    # Returns String
    def to
      @to ||= unquoted_address_header(:to)
    end

    # Unquotes and converts the Cc header to UTF-8.
    #
    # Returns String
    def cc
      @cc ||= unquoted_address_header(:cc)
    end

    # Unquotes and converts the Subject header to UTF-8.
    #
    # Returns String
    def subject
      @mail.subject
    end

    # Gets the unique message-id for the email, with the surrounding < and > 
    # parsed out.
    #
    # Returns String
    def message_id
      @mail.message_id
    end

    # Gets the plain/text body of the email.
    #
    # Returns String
    def body
      process_message_body if !@body
      @body
    end

    # Gets the html body of the email.
    #
    # Returns String
    def html
      process_message_body if !@html
      @html
    end

    # Gets the attachments in the email.
    #
    # Returns Array of Astrotrain::Attachment objects.
    def attachments
      process_message_body if !@attachments
      @attachments
    end

    # Builds a hash of headers, skipping the keys specified in
    # #skipped_headers.  If header values cannot be parsed, the original
    # raw value is provided.
    #
    # Returns Hash of the headers with String keys and values.
    def headers
      @headers ||= begin
        @mail.header.fields.inject({}) do |memo, field|
          name = field.name.downcase
          self.class.skipped_headers.include?(name) ?
            memo :
            memo.update(name => self.class.unescape(unquoted_header(name)))
        end
      end
    end

    # UTILITY METHODS

    # Returns Array of full email addresses from the TO header.
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_to
      @mail.to
    end

    # Returns Array of full email addresses from the Delivered-To header.
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_delivered_to
      @recipients_from_delivered_to ||= begin
        arr = [@mail['delivered-to']]
        arr.compact!
        arr.flatten!
        arr.map! { |e| e.to_s }
      end
    end

    # Returns Array of full email addresses from the X-Original-To header.
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_original_to
      @recipients_from_original_to ||= begin
        arr = [@mail['x-original-to']]
        arr.compact!
        arr.flatten!
        arr.map! { |e| e.to_s }
      end
    end

    # Parses out all email addresses from the body of the email.
    #
    # Returns Array of full email addresses from the email body
    #   ex: ["foo <foo@bar.com>"]
    def recipients_from_body
      @recipients_from_body ||= body.scan(EMAIL_REGEX)
    end

    # Parses the quoted header values: `=?...?=`.
    #
    # key - String header key
    #
    # Returns unquoted String.
    def unquoted_header(key)
      if header = @mail[key]
        Mail::Encodings.value_decode(header.value)
      else
        ''
      end
    end

    def unquoted_address_header(key)
      if header = @mail[key]
        addrs = Mail::AddressList.new(header.value)
        addrs.addresses.each { |a| a.decoded }
      else
        []
      end
    end

    # Returns a clean set of email addresses from the array of email headers.
    # Any blank or invalid emails are dropped.
    #
    # emails - Array of email headers.
    #
    # Returns Array of email addresses.
    def self.parse_email_addresses(emails)
      parsed = emails.inject([]) do |memo, email|
        memo.push *parse_email_address(email)
      end
      parsed.flatten!
      parsed.uniq!
      parsed.delete_if { |email| !email || email.size.zero? }
      parsed.each { |email| unescape(email) }
    end

    # Parses just the email address out of an email header.  In the case of a 
    # parsing error, use a regex to pull any emails out.
    #
    #   Astrotrain::Message.parse_email_address("rick <rick@foo.com>") 
    #     # => "rick@foo.com"
    #
    # email - header String
    #
    # Returns email String.
    def self.parse_email_address(email)
      list = Mail::AddressList.new(email).addresses.
        map! { |a| a.address }
    rescue Mail::Field::ParseError
      email.scan(EMAIL_REGEX)
    end

    # Stolen from Rack/Camping, remove the "+" => " " translation
    def self.unescape(s)
      s.gsub!(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
      s
    end

    # Parses the mail's parts, assembling the plain/HTML Strings, as well as
    # any attachments.
    #
    # Returns nothing.
    def process_message_body
      @attachments = []
      if @mail.multipart?
        @body, @html = [], []
        scan_parts(@mail)
        @body = @body.join("\n")
        @html = @html.join("\n")
      else
        if @mail.content_type =~ /text\/html/
          @html = @mail.body.to_s
          @body = ''
        else
          @body = @mail.body.to_s
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
            when /text\/plain/
              @body << part.body.to_s
            when /text\/html/
              @html << part.body.to_s
            else
              att = Attachment.new(part)
              @attachments << att if att.attached?
          end
        end
      end
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