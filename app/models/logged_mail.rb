class LoggedMail
  include DataMapper::Resource

  class << self
    attr_accessor :log_path
  end

  self.log_path       = Merb.root / 'messages'

  property :id,         Serial
  property :mapping_id, Integer, :nullable => false, :index => true
  property :recipient,  String
  property :subject,    String
  property :filename,   String
  property :created_at, DateTime

  belongs_to :mapping

  def self.from(message, mapping)
    logged = new :filename => message.filename, :recipient => message.recipient(mapping.recipient_header_order), :subject => message.subject, :mapping_id => mapping.id
    logged.save
    logged
  end

  def raw
    @raw ||= filename.blank? ? nil : IO.read(raw_path)
  end

  def raw_path
    @raw_path ||= self.class.log_path / filename
  end
end
