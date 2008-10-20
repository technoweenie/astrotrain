class Mapping
  include DataMapper::Resource

  class << self
    attr_accessor :default_domain
  end
  self.default_domain = 'astrotrain.com'

  property :id,           Serial
  property :user_id,      Integer, :nullable => false, :index => true
  property :email_user,   String, :size => 255, :length => 1..255, :index => :email, :format => /^[\w\.\_\%\+\-]*\*?$/
  property :email_domain, String, :size => 255, :lenght => 1..255, :index => :email, :format => /^[\w\-\_\.]+$/, :default => lambda { default_domain }
  property :destination,  String, :size => 255, :length => 1..255, :unique_index => true, :unique => true
  property :transport,    String, :size => 255, :set => %w(http_post jabber), :default => 'http_post'

  validates_is_unique :email_user, :scope => :email_domain
  validates_format :destination, :as => :url, :if => :destination_uses_url?
  validates_format :destination, :as => :email_address, :if => :destination_uses_email?

  belongs_to :user
  has n, :logged_mails

  def self.match(email_address)
    email_address.strip!
    email_address.downcase!
    name, domain = email_address.split("@")
    match_by_address(name, domain) || match_by_wildcard(name, domain)
  end

  def self.process(message)
    if mapping = match(message.recipient)
      mapping.process(message)
    end
  end

  def process(message)
    Transport.process(message, self)
    log_message(message)
  end

  def log_message(message)
    logged = LoggedMail.from(message)
    logged_mails << logged
    logged.save
    logged
  end

  def match?(name)
    name =~ email_user_regex
  end

  def destination_uses_url?
    transport == 'http_post'
  end

  def destination_uses_email?
    transport == 'jabber'
  end

protected
  def self.match_by_address(name, domain)
    first(:email_user => name, :email_domain => domain)
  end

  def self.match_by_wildcard(name, domain)
    wildcards = all(:email_domain => domain, :email_user.like => "%*")
    wildcards.sort! { |x, y| y.email_user.size <=> x.email_user.size }
    wildcards.detect { |w| w.match?(name) }
  end

  def email_user_regex
    @email_user_regex ||= begin
      if email_user['*']
        /^#{email_user.sub /\*/, '(.*)'}$/
      else
        /^#{email_user}$/
      end
    end
  end
end
