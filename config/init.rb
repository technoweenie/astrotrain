# Go to http://wiki.merbivore.com/pages/init-rb
 
require File.join(File.dirname(__FILE__), 'dependencies.rb')
 
use_orm :datamapper
use_test :rspec
use_template_engine :erb
 
Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '1205346b9baa87cf8e49f78124c8d17a31ac0971'  # required for cookie session store
  # c[:session_id_key] = '_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
end
 
Merb::BootLoader.after_app_loads do
  require 'mapping/transport'
  require 'mapping/http_post'
end
