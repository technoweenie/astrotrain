module Astrotrain
  # custom subclass of TMail::Mail that fixes some bugs.  The fixes were pushed upstream,
  # and this class will go away once the gem is released.
  class Mail < TMail::Mail
    # Allows multiple values for this header
    ALLOW_MULTIPLE['delivered-to'] = true
  end
end

module TMail
  # small tweak to provide the raw body of headers in case they're unable to 
  # be parsed properly
  class HeaderField
    def raw_body
      @body
    end
  end
end