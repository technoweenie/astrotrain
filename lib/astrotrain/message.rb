# encoding: UTF-8

require 'mail'
require 'set'

module Astrotrain
  # Wrapper around a TMail object
  class Message
    EMAIL_REGEX = /[\w\.\_\%\+\-]+[^\s\.]@[\w\-\_\.]+/

    # Reference to the internal Mail object that parsed the raw email.
    attr_reader :mail

    # Refebrence to the original file that this Mail came from.
    attr_reader :path

    class << self
      attr_accessor :recipient_header_order, :skipped_headers
    end

    # Astrotrain::Message#headers does not show these headers
    self.skipped_headers = Set.new %w(to cc from subject delivered-to
      x-original-to received)

    # This is the default order that Astrotrain will search for a matching
    # recipient.  Set this to a different order.  Add "body" to the list if
    # you want to scan the body for email addresses with EMAIL_REGEX.
    self.recipient_header_order = %w(original_to delivered_to to)

    # Public: Parses the raw email headers into a Astrotrain::Message instance.
    #
    # path - String path to the file.
    #
    # Returns Astrotrain::Message instance.
    def self.read(path)
      new(::Mail.read(path), path)
    end

    # Public: Parses the raw email headers into a Astrotrain::Message instance.
    #
    # raw - String of the email content
    #
    # Returns Astrotrain::Message instance.
    def self.parse(raw)
      new(::Mail.new(raw))
    end

    def initialize(mail, path = nil)
      @body = @html = @attachments = nil
      @path        = path
      @mail        = mail
      @recipients  = {}
    end

    # Public: Gets the recipients of an email using the
    # To/Delivered-To/X-Original-To headers.  It's not always straightforward
    # which email we want when dealing with filters and forward rules.
    #
    # order - Array of email header names that specifies the order that the
    #         list of recipient emails is assembled.  Valid strings are:
    #         'original_to', 'delivered_to', and 'to'.
    #
    # Returns Array of possible recipients.
    def recipients(order = nil)
      if !@recipients.key?(order)
        order = Array(order)
        order = self.class.recipient_header_order if order.empty?
        recipients = []

        emails = order.inject([]) do |memo, key|
          memo.push *send("recipients_from_#{key}")
        end

        @recipients[order] = emails.map! { |em| em.address }
        @recipients[order].uniq!
      end
      @recipients[order]
    end

    # Public: Unquotes and converts the From header to UTF-8.
    #
    # Returns Array of Mail::Address objects
    def from
      @from ||= unquoted_address_header(:from)
    end
    alias sender from

    # Public: Unquotes and converts the To header to UTF-8.
    #
    # Returns Array of Mail::Address objects
    def to
      @to ||= unquoted_address_header(:to)
    end

    # Public: Unquotes and converts the Cc header to UTF-8.
    #
    # Returns Array of Mail::Address objects
    def cc
      @cc ||= unquoted_address_header(:cc)
    end

    # Public: Unquotes and converts the Subject header to UTF-8.
    #
    # Returns String
    def subject
      @mail.subject
    end

    # Public: Gets the unique message-id for the email, with the surrounding
    # `<` and `>` parsed out.
    #
    # Returns String
    def message_id
      @mail.message_id
    end

    # Public: Gets the plain/text body of the email.
    #
    # Returns String
    def body
      process_message_body if !@body
      @body
    end

    # Public: Gets the html body of the email.
    #
    # Returns String
    def html
      process_message_body if !@html
      @html
    end

    # Public: Gets the attachments in the email.
    #
    # Returns Array of Astrotrain::Attachment objects.
    def attachments
      process_message_body if !@attachments
      @attachments
    end

    # Public: Builds a hash of headers, skipping the keys specified in
    # #skipped_headers.  If header values cannot be parsed, the original
    # raw value is provided.
    #
    # Returns Hash of the headers with String keys and values.
    def headers
      @headers ||= begin
        @mail.header.fields.inject({}) do |memo, field|
          name = field.name.downcase.to_s
          next memo if self.class.skipped_headers.include?(name)

          header = unquoted_header(name)
          memo.update(name => self.class.unescape(header))
        end
      end
    end

    # UTILITY METHODS

    # Parses the 'To' header for email address.
    #
    # Returns Array of Mail::Address objects
    def recipients_from_to
      to
    end

    # Parses the 'Delivered-To' header for email address.
    #
    # Returns Array of Mail::Address objects
    def recipients_from_delivered_to
      @recipients_from_delivered_to ||= unquoted_address_header('delivered-to')
    end

    # Parses the 'X-Original-To' header for email address.
    #
    # Returns Array of Mail::Address objects
    def recipients_from_original_to
      @recipients_from_original_to ||= unquoted_address_header('x-original-to')
    end

    # Parses out all email addresses from the body of the email.
    #
    # Returns Array of Mail::Address objects
    def recipients_from_body
      @recipients_from_body ||= begin
        emails_from_body = body.scan(EMAIL_REGEX)
        address_list_for(emails_from_body, true)
      rescue Mail::Field::ParseError
        []
      end
    end

    # Parses the quoted header values: `=?...?=`.
    #
    # key - String or Symbol header name
    #
    # Returns unquoted String.
    def unquoted_header(key)
      if header = @mail[key]
        value = header.respond_to?(:map) ?
          header.map { |h| h.value }.join("\n") :
          header.value
        Mail::Encodings.value_decode(value)
      else
        ''
      end
    end

    # Parses the given header for email addresses. Handles the case where some
    # keys return arrays if there are multiple values.
    #
    # key - String or Symbol header name
    #
    # Returns Array of Mail::Address objects
    def unquoted_address_header(key)
      if header = @mail[key]
        emails = if header.respond_to?(:value)
          [header.value]
        else
          header.map { |h| h.value }
        end
        address_list_for(emails)
      else
        []
      end
    end

    # Uses Mail::AddressList to parse the given comma separated emails.
    #
    # emails - Array of String email headers.
    #          Example: ["foo@example.com, Bar <bar@example.com>", ...]
    #
    # Returns Array of Mail::Address objects
    def address_list_for(emails, retried = false)
      emails = emails * ", "
      list   = Mail::AddressList.new(self.class.unescape(emails))
      addrs  = list.addresses.each { |a| a.decoded }
      addrs.uniq!
      addrs
    rescue Mail::Field::ParseError
      if retried
        raise
      else
        address_list_for(emails.scan(EMAIL_REGEX), true)
      end
    end

    # Stolen from Rack/Camping, remove the "+" => " " translation
    def self.unescape(s)
      s.gsub!(/((?:%[0-9a-fA-F]{2})+)/n) do
        original = $1.dup
        replacement = [$1.delete('%')].pack('H*')
        replacement.as_utf8.valid? ? replacement : original
      end
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

      @body = convert_to_utf8(@body)
      @html = convert_to_utf8(@html)
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

    # Converts a given String to UTF-8.
    # If the message has no charset assigned, we'll attempt to detect it
    # then convert it to UTF-8.
    #
    # s - unconverted String in the wrong character set
    #
    # Returns converted String.
    def convert_to_utf8(s)
      # If this string is already valid UTF-8 just hand it back
      if (!@mail.charset || @mail.charset == 'UTF-8') && s.as_utf8.valid?
        s.force_encoding("UTF-8") if s.respond_to?(:force_encoding)
        return s
      end

      # First lets try to detect the encoding if the message didn't specify
      if !@mail.charset && detection = CharlockHolmes::EncodingDetector.detect(s)
        @mail.charset = detection[:encoding]
      end

      # if the encoding was already set or we just detected it AND it's not already
      # set to UTF-8 - try to transcode the body into UTF-8
      if @mail.charset && @mail.charset != 'UTF-8'
        if s.size > 0
          s = CharlockHolmes::Converter.convert s, @mail.charset, 'UTF-8'
        else
          s = ""
        end
      end

      # By the time we get here, `s` is either UTF-8 or we need to force it to be
      # But, even if it's UTF-8 we could be in the case where the charset on the
      # message was set to UTF-8 but is in fact invalid.
      # So for either case, we want to make sure the output is valid UTF-8 - even
      # if it means mutating the invalid string.
      # Also we're not reusing the String::UTF8 version of `s` from above here
      # because by this point, it may be a new string.
      s.as_utf8.clean.as_raw
    end
  end
end
