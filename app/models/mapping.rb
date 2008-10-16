class Mapping
  include DataMapper::Resource

  class << self
    attr_accessor :default_domain
  end
  self.default_domain = 'astrotrain.com'

  property :id,           Serial
  property :user_id,      Integer, :nullable => false, :index => true
  property :email_user,   String, :size => 255, :length => 1..255, :index => :email, :format => /^[\w\.\_\%\+\-]+$/
  property :email_domain, String, :size => 255, :lenght => 1..255, :index => :email, :format => /^[\w\-\_\.]+$/, :default => lambda { default_domain }
  property :post_url,     String, :size => 255, :length => 1..255, :unique_index => true, :unique => true, :format => /^https?:\/\/([\w\-\_\.]+)+(\/[\w\-\ \.\/\?\%\&\=\[\]]*)?$/

  validates_is_unique :email_user, :scope => :email_domain

  belongs_to :user
  has n, :logged_mails
end
