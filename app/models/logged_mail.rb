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
  before :save do
    if delivered_at && filename
      FileUtils.rm_rf raw_path if File.exist?(raw_path)
      self.filename = nil
    end
  end

  def self.from(message)
    logged = new(:filename => message.filename, :subject => message.subject)
    if !block_given? || yield(logged)
      logged.save
    end
    logged
  end

  def raw
    @raw ||= (!filename.blank? && File.exist?(raw_path)) ? IO.read(raw_path) : nil
  end

  def raw_path
    @raw_path ||= self.class.log_path / filename
  end
end
