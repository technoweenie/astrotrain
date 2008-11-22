class LoggedMail
  include DataMapper::Resource

  property :id,         Serial
  property :mapping_id, Integer, :nullable => false, :index => true
  property :recipient,  String
  property :subject,    String
  property :raw,        Text
  property :created_at, DateTime

  belongs_to :mapping

  def self.from(message, mapping)
    logged = new :recipient => message.recipient(mapping.recipient_header_order), :subject => message.subject, :raw => message.raw, :mapping_id => mapping.id
    logged.save
    logged
  end
end
