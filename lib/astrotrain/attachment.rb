module Astrotrain
  class Attachment
    def initialize(part)
      @part    = part
      @is_read = false
    end

    def content_type
      @part.content_type
    end

    def filename
      @filename ||= begin
        f = @part.type_param("name") || @part.disposition_param('filename')
        f.strip!
        f
      end
    end

    # For IO API compatibility when used with Rest-Client
    def close
    end

    alias path filename

    def read(value = nil)
      if read?
        nil
      else
        @is_read = true
        data
      end
    end

    def read?
      @is_read == true
    end

    def data
      @part.body
    end

    def attached?
      !filename.nil?
    end

    def ==(other)
      super || (filename == other.filename && content_type == other.content_type)
    end

    def inspect
      %(#<Message::Attachment filename=#{filename.inspect} content_type=#{content_type.inspect}>)
    end
  end
end