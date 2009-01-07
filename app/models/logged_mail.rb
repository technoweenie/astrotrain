class LoggedMail
  include DataMapper::Resource

  class << self
    attr_accessor :log_path
  end

  self.log_path       = Merb.root / 'messages'

  property :id,            Serial
  property :mapping_id,    Integer, :index => true
  property :recipient,     String
  property :subject,       String
  property :filename,      String
  property :created_at,    DateTime
  property :delivered_at,  DateTime
  property :error_message, String

  belongs_to :mapping

  attr_accessor :message

  def self.from(message)
    logged = new
    logged.set_message(message)
    if !block_given? || yield(logged)
      logged.save
    end
    logged
  end

  def set_message(message)
    self.filename = message.filename
    self.subject  = message.subject
    @message      = message
  end

  def set_mapping(mapping)
    self.recipient = @message.recipient(mapping.recipient_header_order) if @message
    self.mapping   = mapping
  end

  def raw
    @raw ||= filename.blank? ? nil : IO.read(raw_path)
  end

  def raw_path
    @raw_path ||= self.class.log_path / filename
  end
end
