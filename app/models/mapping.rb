class Mapping
  include DataMapper::Resource
  
  property :id, Serial
  property :email_user, String
  property :post_url, String
  property :user_id, Integer

  belongs_to :user
end
