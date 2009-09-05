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

    validates_is_unique :email_user, :scope => :email_domain
    validates_format :destination, :as => /^(https?:)\/\/[^\/]+\/?/i, :if => :destination_uses_url?
    validates_format :destination, :as => :email_address, :if => :destination_uses_email?

    has n, :logged_mails, :order => [:created_at.desc]

    # returns a mapping for the given array of email addresses
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

    # Processes a given message.  It finds a mapping, creates a LoggedMail record,
    # and attempts to process the message.
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

    # Processes a given message and recipient against the mapping's transport.
    def process(message, recipient)
      Transport.process(message, self, recipient)
    end

    # returns true if the email matches this mapping.  Wildcards in the name are allowed.
    # A mapping with foo*@bar.com will match foo@bar.com and food@bar.com, but not foo@baz.com.
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

    # Looks for the mapping's separator in the message body and pulls only the content
    # above it.  Assuming a separator of '===='...
    #
    #   This will be kept
    #   
    #   On Thu, Sep 3, 2009 at 12:34 AM... (this will be removed)
    #   ====
    #
    #   > Everything here will be removed.
    #
    def find_reply_from(body)
      return    if separator.blank?
      return '' if body.blank?
      lines = body.split("\n")
      delim_line = found_empty = nil

      (lines.size - 1).downto(0) do |i|
        line = lines[i]
        if !delim_line && line.include?(separator)
          delim_line = i
        elsif delim_line && !found_empty
          delim_line = i
          found_empty = line.strip.blank?
        elsif delim_line && found_empty
          if date_reply_line?(line) || line.strip.blank?
            delim_line = i
          else
            break
          end
        end
      end

      if delim_line
        body = if delim_line.zero?
          []
        elsif lines.size >= delim_line
          lines[0..delim_line-1]
        else
          lines
        end.join("\n")
      elsif body.frozen?
        body = body.dup
      end
      body.strip!
      body
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

    DATE_LANGUATE_REGEXES = [/^on\b.*wrote\b?:$/i, /^am\b.*schrieb [\w\d\s]+:$/i, /^le\b.*a écrit\b?:$/i]
    def date_reply_line?(line)
      DATE_LANGUATE_REGEXES.any? { |re| line =~ re }
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