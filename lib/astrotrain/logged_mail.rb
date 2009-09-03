module Astrotrain
  # Logs details of each incoming message.  
  class LoggedMail
    include DataMapper::Resource

    class << self
      attr_accessor :log_path, :log_processed
    end

    # Enabling this will save records for every processed email, not just the errored emails.
    self.log_processed = false
    self.log_path      = File.join(Astrotrain.root, 'messages')

    property :id,            Serial
    property :mapping_id,    Integer, :index => true
    property :sender,        String,  :index => true, :size => 255, :length => 1..255
    property :recipient,     String,  :index => true, :size => 255, :length => 1..255
    property :subject,       String,  :index => true, :size => 255, :length => 1..255
    property :created_at,    DateTime
    property :delivered_at,  DateTime
    property :error_message, String, :size => 255, :length => 1..255

    belongs_to :mapping

    def self.from(message)
      logged = new
      begin
        logged.sender  = Message.parse_email_addresses(:from, message.sender).first
        logged.subject = message.subject
      end
      if !block_given? || yield(logged)
        logged.save
      end
      logged
    end
  end
end