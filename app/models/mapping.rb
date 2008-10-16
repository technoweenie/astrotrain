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
  property :post_url,     String, :size => 255, :length => 1..255, :unique_index => true, :unique => true, :format => /^https?:\/\/([\w\-\_\.]+)+(\/[\w\-\ \.\/\?\%\&\=\[\]]*)?$/

  validates_is_unique :email_user, :scope => :email_domain

  belongs_to :user
  has n, :logged_mails

  def self.match(email_address)
    email_address.strip!
    email_address.downcase!
    name, domain = email_address.split("@")
    if mapping = first(:email_user => name, :email_domain => domain)
      mapping
    elsif domain != default_domain
      wildcards = all(:email_domain => domain, :email_user.like => "%*")
      wildcards.sort! { |x, y| y.email_user.size <=> x.email_user.size }
      wildcards.detect { |w| w.match?(name) }
    end
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

  def match?(name)
    name =~ email_user_regex
  end
end
