require 'digest/sha1'
require 'fileutils'
class Message
  attr_reader :mail
  class << self
    attr_reader :queue_path
  end

  def self.queue_path=(path)
    FileUtils.mkdir_p path
    @queue_path = File.expand_path(path)
  end

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
  end

  def self.parse(raw)
    new TMail::Mail.parse(raw)
  end

  def initialize(mail)
    @mail = mail
    @mapping = nil
  end

  def recipient
    @recipient ||= begin
      if value = @mail['X-Original-To']
        value.to_s
      elsif value = @mail['Delivered-To']
        value.to_s
      else
        @mail.to.first.to_s
      end
    end
  end

  def senders
    @senders ||= @mail.from.map { |f| f.to_s }
  end

  def subject
    @mail.subject
  end

  def body
    @mail.body
  end

  def raw
    @mail.port.to_s
  end
end