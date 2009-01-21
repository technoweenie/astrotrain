ver = '1.0.7.1'
dependency "merb-action-args", ver   # Provides support for querystring arguments to be passed in to controller actions
dependency "merb-assets", ver        # Provides link_to, asset_path, auto_link, image_tag methods (and lots more)
dependency "merb-cache", ver         # Provides your application with caching functions 
dependency "merb-helpers", ver       # Provides the form, date/time, and other helpers
dependency "merb-mailer", ver        # Integrates mail support via Merb Mailer
dependency "merb-slices", ver        # Provides a mechanism for letting plugins provide controllers, views, etc. to your app
dependency "merb-auth", ver          # An authentication slice (Merb's equivalent to Rails' restful authentication)
dependency "merb-param-protection", ver
 
dm_ver = "0.9.9"
dependency "dm-core", dm_ver         # The datamapper ORM
dependency "dm-aggregates", dm_ver   # Provides your DM models with count, sum, avg, min, max, etc.
dependency "dm-migrations", dm_ver   # Make incremental changes to your database.
dependency "dm-timestamps", dm_ver   # Automatically populate created_at, created_on, etc. when those properties are present.
dependency "dm-types", dm_ver        # Provides additional types, including csv, json, yaml.
dependency "dm-validations", dm_ver  # Validation framework

dependency "tmail", "1.2.3.1"
dependency "xmpp4r-simple", "0.8.8"

$LOAD_PATH.unshift File.join(Merb.root, 'vendor', 'rest-client', 'lib')
require 'rest_client'
