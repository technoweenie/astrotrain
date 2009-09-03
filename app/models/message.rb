require 'digest/sha1'
require 'fileutils'
require 'tempfile'
require 'set'

# Wrapper around a TMail object
class Message
  attr_accessor :body
  attr_reader :mail, :attachments

  class << self
    attr_reader   :queue_path, :archive_path
    attr_accessor :recipient_header_order, :skipped_headers, :log_processed_messages
  end

  self.log_processed_messages = false

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

  self.skipped_headers = Set.new %w(date from subject delivered-to x-original-to received)
  self.recipient_header_order = %w(original_to delivered_to to)
  self.queue_path = File.join(File.dirname(__FILE__), '..', '..', 'queue')

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

  def self.receive(raw)
    message = parse(raw)
    Mapping.process(message)
    message
  end

  def self.receive_file(path, raw = nil)
    message = receive IO.read(path)
    if archive_path
      FileUtils.mv path, archive_path / Time.now.year.to_s / Time.now.month.to_s / Time.now.day.to_s / File.basename(path)
    else
      FileUtils.rm_rf path
    end
    message
  end

  def self.parse(raw)
    new Astrotrain::Mail.parse(raw)
  end

  def initialize(mail)
    @mail        = mail
    @mapping     = nil
    @attachments = []
    @recipients  = {}
  end

  def recipients(order = nil)
    if !@recipients.key?(order)
      order = self.class.recipient_header_order if order.blank?
      recipients = []

      parse_email_headers recipients_from_body, recipients
      order.each do |key|
        parse_email_headers send("recipients_from_#{key}"), recipients
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

  def body
    @body ||= begin
      if @mail.multipart?
        @attachments.clear
        @body = []
        scan_parts(@mail)
        @body = @body.join("\n")
      else
        @body = @mail.body
      end
      @mail.charset ? @body : convert_to_utf8(@body)
    end
  end

  def raw
    @mail.port.to_s
  end

  def headers
    @headers ||= begin
      h = {}
      @mail.header.each do |key, value|
        next if self.class.skipped_headers.include?(key)
        h[key] = value.to_s
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

    def inspect
      %(#<Message::Attachment filename=#{filename.inspect} content_type=#{content_type.inspect}>)
    end
  end

protected
  def scan_parts(message)
    message.parts.each do |part|
      if part.multipart?
        scan_parts(part)
      else
        if part.content_type == "text/plain"
          @body << part.body
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
        emails = TMail::AddressHeader.new('to', value)
        emails.addrs.each do |addr|
          email = TMail::Address.parse(addr.to_s)
          collection << unescape(email.address)
        end
      end
    end
  end

  # Stolen from Rack/Camping, remove the "+" => " " translation
  def unescape(s)
    s.gsub!(/((?:%[0-9a-fA-F]{2})+)/n){
      [$1.delete('%')].pack('H*')
    }
    s
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