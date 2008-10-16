class Message
  attr_reader :mail

  def self.receive(raw)
    message = parse(raw)
    if message.mapping
      message.log_to message.mapping
    end
  end

  def self.parse(raw)
    new TMail::Mail.parse(raw)
  end

  def initialize(mail)
    @mail = mail
    @default_domain = @mapping = nil
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

  def default_domain?
    @default_domain.nil? ? (@default_domain = recipient =~ /\@#{Mapping.default_domain}$/) : @default_domain
  end

  def mapping
    if @mapping.nil?
      name, domain = recipient.split("@")
      @mapping = find_mapping_by_email name, domain
    end
    @mapping
  end

  def log_to(mapping)
    logged = LoggedMail.from(self)
    mapping.logged_mails << logged
    logged.save
    logged
  end

protected
  def find_mapping_by_email(name, domain)
    Mapping.first :email_user => name, :email_domain => domain
  end
end