module Astrotrain
  class Mapping
    include DataMapper::Resource

    class << self
      attr_accessor :default_domain
      attr_accessor :transports
    end

    self.transports     = {"HTTP Post" => 'http_post', "Jabber" => 'jabber'}
    self.default_domain = 'astrotrain.com'

    property :id,           Serial
    property :email_user,   String, :size => 255, :length => 1..255, :index => :email, :format => /^[\w\.\_\%\+\-]*\*?$/
    property :email_domain, String, :size => 255, :lenght => 1..255, :index => :email, :format => /^[\w\-\_\.]+$/, :default => lambda { default_domain }
    property :destination,  String, :size => 255, :length => 1..255
    property :transport,    String, :size => 255, :set => transports.values, :default => 'http_post'
    property :separator,    String, :size => 255
    property :recipient_header_order, String, :size => 255, :auto_validation => false

    validates_is_unique :email_user, :scope => :email_domain
    validates_format :destination, :as => /^(https?:)\/\/[^\/]+\/?/i, :if => :destination_uses_url?
    validates_format :destination, :as => :email_address, :if => :destination_uses_email?
    validates_with_block :recipient_header_order do
      if order = recipient_header_order
        if !order.all? { |key| Message.recipient_header_order.include?(key) }
          [false, "Field should be an array with these choices: delivered_to, original_to, and to"]
        else
          true
        end
      else
        true
      end
    end

    has n, :logged_mails, :order => [:created_at.desc]

    def self.match(email_addresses)
      email_addresses.each do |email_address|
        email_address.strip!
        email_address.downcase!
        name, domain = email_address.split("@")
        if mapping = match_by_address(name, domain) || match_by_wildcard(name, domain)
          return [mapping, email_address]
        end
      end
      nil
    end

    def self.process(message)
      LoggedMail.from(message) do |logged|
        begin
          mapping, recipient = match(message.recipients)
          if mapping
            logged.recipient = recipient
            logged.mapping   = mapping
            mapping.process(message, recipient)
            logged.delivered_at = Time.now.utc
          end
          LoggedMail.log_processed # save successfully processed messages?
        rescue
          logged.error_message = "#{$!.class}: #{$!}"
        end
      end
    end

    def process(message, recipient)
      Transport.process(message, self, recipient)
    end

    def recipient_header_order
      if s = attribute_get(:recipient_header_order)
        s.split(",")
      end
    end

    def recipient_header_order=(value)
      value = \
        case value
          when Array  then value * ','
          when String then value
          else nil
        end
      attribute_set(:recipient_header_order, value)
    end

    def match?(name, domain)
      email_domain == domain && name =~ email_user_regex
    end

    def destination_uses_url?
      transport == 'http_post'
    end

    def destination_uses_email?
      transport == 'jabber'
    end

    def full_email
      "#{email_user}@#{email_domain}"
    end

    def find_reply_from(body)
      return if separator.blank?
      lines = body.split("\n")
      delim_line = last_line = found_empty = nil
    
      lines.each_with_index do |line, i|
        next if delim_line
        delim_line = i if line.include?(separator)
      end

      while !last_line && delim_line.to_i > 0
        delim_line = delim_line - 1
        if found_empty
          last_line = delim_line if lines[delim_line].strip.size > 0
        else
          found_empty = true if lines[delim_line].strip.size.zero?
        end
      end

      if last_line
        lines = lines[0..delim_line]
        strip_date_reply_line_from lines
        body = lines * "\n"
      elsif !delim_line.nil?
        body = ''
      end

      if body.frozen?
        body.strip
      else
        body.strip!
        body
      end
    end

  protected
    def self.match_by_address(name, domain)
      first(:email_user => name, :email_domain => domain)
    end

    def self.match_by_wildcard(name, domain)
      wildcards = all(:email_domain => domain, :email_user.like => "%*")
      wildcards.sort! { |x, y| y.email_user.size <=> x.email_user.size }
      wildcards.detect { |w| w.match?(name, domain) }
    end

    @@language_regexes = [/^on\b.*wrote\b?:$/i, /^am\b.*schrieb [\w\d\s]+:$/i, /^le\b.*a écrit\b?:$/i]
    def strip_date_reply_line_from(lines)
      @@language_regexes.detect do |lang_re|
        if lines.last =~ lang_re
          lines.pop
        end
      end
      lines
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
end