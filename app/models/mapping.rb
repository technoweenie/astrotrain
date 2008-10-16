class Mapping
  include DataMapper::Resource

  class << self
    attr_accessor :default_domain
  end
  self.default_domain = 'astrotrain.com'

  property :id,         Serial
  property :email_user, String
  property :post_url,   String
  property :user_id,    Integer

  belongs_to :user
end
