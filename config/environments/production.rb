Merb.logger.info("Loaded PRODUCTION Environment...")
Merb::Config.use { |c|
  c[:exception_details] = false
  c[:reload_classes] = false
  c[:log_level] = :error
  
  c[:log_file]  = Merb.root / "log" / "production.log"
  # or redirect logger using IO handle
  # c[:log_stream] = STDOUT
}

Merb::BootLoader.after_app_loads do
  Mapping::Transport.processing = true
  deployment = Merb.root / 'config' / 'deployment.rb'
  require deployment if File.exist?(deployment)
end