class Mapping
  include DataMapper::Resource

  class << self
    attr_accessor :default_domain
  end
  self.default_domain = 'astrotrain.com'

  property :id,         Serial
  property :email_user, String, :length => 1..255, :unique_index => true, :unique => true, :format => /^[\w\.\_\%\+\-]+$/
  property :post_url,   String, :length => 1..255, :unique_index => true, :unique => true, :format => /^https?:\/\/([\w\-\_\.]+)+(\/[\w\-\ \.\/\?\%\&\=\[\]]*)?$/
  property :user_id,    Integer, :nullable => false, :index => true

  belongs_to :user
end
