class Message
  attr_reader :mail

  def self.parse(raw)
    new TMail::Mail.parse(raw)
  end

  def initialize(mail)
    @mail = mail
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
end