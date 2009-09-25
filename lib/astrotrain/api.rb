require 'sinatra'

before do
  response['Content-Type'] = 'text/plain'
end

get '/queue_size' do
  if File.exist?(Astrotrain::Message.queue_path)
    (Dir.entries(Astrotrain::Message.queue_path).size - 2).to_s
  else
    '0'
  end
end

get '/queue/*' do
  path = params[:splat].first
  path.gsub! /^\/+/, ''
  file = File.join(Astrotrain::Message.queue_path, path)
  if File.exist?(file)
    IO.read(file)
  else
    halt 404, "#{path.inspect} was not found."
  end
end

get '/queue' do
  data = []
  Dir.entries(Astrotrain::Message.queue_path).each do |e|
    data << e unless e =~ /^\.{1,2}$/
  end
  data * "\n"
end

unless $testing
  configure do
    # the idea being, you pass the name of the config file
    #
    #   # loads File.join(Dir.pwd, 'config.rb')
    #   CONFIG=config ruby lib/astrotrain/api.rb
    #
    #   # loads File.join(Dir.pwd, 'config.rb')
    #   ruby lib/astrotrain/api.rb config
    #
    # That file contains the Greymalkin.load block that initializes Sequel
    #
    path = ENV['CONFIG'] || ARGV.shift
    if path[0..0] != '/'
      path = File.join(Dir.pwd, path)
    end
    require File.expand_path(path)
  end
end
