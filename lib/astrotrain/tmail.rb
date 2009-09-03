module Astrotrain
  # custom subclass of TMail::Mail that fixes some bugs.  The fixes were pushed upstream,
  # and this class will go away once the gem is released.
  class Mail < TMail::Mail
    def charset( default = nil )
      if h = @header['content-type']
        h['charset'] || mime_version_charset || default
      else
        mime_version_charset || default
      end
    end

    # some weird emails come with the charset specified in the mime-version header:
    #
    #  #<TMail::MimeVersionHeader "1.0\n charset=\"gb2312\"">
    #
    def mime_version_charset
      if header['mime-version'].inspect =~ /charset=('|\\")?([^\\"']+)/
        $2
      end
    end

    # copied from TMail::Mail, uses #charset instead of #sub_header
    def unquoted_body(to_charset = 'utf-8')
      from_charset = charset
      case (content_transfer_encoding || "7bit").downcase
        when "quoted-printable"
          # the default charset is set to iso-8859-1 instead of 'us-ascii'.
          # This is needed as many mailer do not set the charset but send in ISO. This is only used if no charset is set.
          if !from_charset.blank? && from_charset.downcase == 'us-ascii'
            from_charset = 'iso-8859-1'
          end

          TMail::Unquoter.unquote_quoted_printable_and_convert_to(quoted_body,
            to_charset, from_charset, true)
        when "base64"
          TMail::Unquoter.unquote_base64_and_convert_to(quoted_body, to_charset,
            from_charset)
        when "7bit", "8bit"
          TMail::Unquoter.convert_to(quoted_body, to_charset, from_charset)
        when "binary"
          quoted_body
        else
          quoted_body
      end
    end
  end
end