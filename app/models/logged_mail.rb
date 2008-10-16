class LoggedMail
  include DataMapper::Resource

  property :id,         Serial
  property :mapping_id, Integer, :nullable => false, :index => true
  property :recipient,  String
  property :subject,    String
  property :raw,        Text
  property :created_at, DateTime

  belongs_to :mapping

  def self.from(message)
    new :recipient => message.recipient, :subject => message.subject, :raw => message.raw
  end
end
