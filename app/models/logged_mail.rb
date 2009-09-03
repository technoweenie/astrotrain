class LoggedMail
  include DataMapper::Resource

  class << self
    attr_accessor :log_path
  end

  self.log_path       = Merb.root / 'messages'

  property :id,            Serial
  property :mapping_id,    Integer, :index => true
  property :sender,        String
  property :recipient,     String
  property :subject,       String
  property :created_at,    DateTime
  property :delivered_at,  DateTime
  property :error_message, String

  belongs_to :mapping

  def self.from(message)
    logged = new
    begin
      logged.sender  = message.sender
      logged.subject = message.subject
    end
    if !block_given? || yield(logged)
      logged.save
    end
    logged
  end
end
