module Astrotrain
  # Simple class that wraps a TMail part attachment in the IO API for 
  # Faraday
  class Attachment
    def initialize(part)
      @data    = nil
      @part    = part
      @is_read = false
    end

    def content_type
      @part.content_type
    end

    def filename
      @part.filename
    end

    alias local_path filename
    alias original_filename filename

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
      @data ||= @part.body.to_s
    end

    def length
      data.size
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
