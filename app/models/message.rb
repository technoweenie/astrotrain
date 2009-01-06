require 'digest/sha1'
require 'fileutils'
require 'tempfile'

# Wrapper around a TMail object
class Message
  attr_accessor :body, :filename
  attr_reader :mail, :attachments

  class << self
    attr_reader   :queue_path
    attr_accessor :recipient_header_order
  end

  def self.queue_path=(path)
    FileUtils.mkdir_p path
    @queue_path = File.expand_path(path)
  end

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
    file = Tempfile.new("astrotrain-#{raw.size}")
    file << raw
    receive_file file.path, raw
  end

  def self.receive_file(path, raw = nil)
    FileUtils.mkdir_p(LoggedMail.log_path)
    filename = File.basename(path)
    FileUtils.mv path, LoggedMail.log_path / filename
    message = parse(raw)
    message.filename = filename
    Mapping.process(message)
  end

  def self.parse(raw)
    new TMail::Mail.parse(raw)
  end

  def initialize(mail)
    @mail        = mail
    @mapping     = nil
    @attachments = []
  end

  def recipient(order = nil)
    order = self.class.recipient_header_order if order.blank?
    order.each do |key|
      value = send("recipient_from_#{key}")
      return value unless value.blank?
    end
  end

  def recipient_from_to
    @recipient_from_to ||= @mail['to'].to_s
  end

  def recipient_from_delivered_to
    @recipient_from_delivered_to ||= @mail['Delivered-To'].to_s
  end

  def recipient_from_original_to
    @recipient_from_original_to ||= @mail['X-Original-To'].to_s
  end

  def sender
    @sender ||= @mail['from'].to_s
  end

  def subject
    @mail.subject
  end

  def body
    @body ||= begin
      if @mail.multipart?
        @attachments.clear
        scan_parts(@mail)
        @body ||= ""
      else
        @mail.body
      end
    end
  end

  def raw
    @mail.port.to_s
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
      @filename ||= @part.type_param("name")
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
          @body = part.body
        else
          att = Attachment.new(part)
          @attachments << att if att.attached?
        end
      end
    end
  end
end