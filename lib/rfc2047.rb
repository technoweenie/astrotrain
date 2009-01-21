#this was pulled from (RFC 2047 decoding library (MIME format for non-ascii in mail headers)) at http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/69323 
require 'iconv'
module Rfc2047
  WORD = %r{=\?([!#\$%&'*+-/0-9A-Z\\^\`a-z{|}~]+)\?([BbQq])\?([!->@-~]+)\?=} # :nodoc:

  # Decodes a string, +from+, containing RFC 2047 encoded words into a target
  # character set, +target+. See iconv_open(3) for information on the
  # supported target encodings. If one of the encoded words cannot be
  # converted to the target encoding, it is left in its encoded form.
  def self.decode_to(target, from)
    out = from.gsub(WORD) do |word|
      charset, encoding, text = $1, $2, $3
      # B64 or QP decode, as necessary:
      case encoding
        when 'b', 'B'
          text = text.unpack('m*')[0]

        when 'q', 'Q'
          # RFC 2047 has a variant of quoted printable where a ' ' character
          # can be represented as an '_', rather than =32, so convert
          # any of these that we find before doing the QP decoding.
          text = text.tr("_", " ")
          text = text.unpack('M*')[0]

        # Don't need an else, because no other values can be matched in a
        # WORD.
      end

      # Convert
      #
      # Remember: Iconv.open(to, from)
      begin
        text = Iconv.open(target, charset) {|i| i.iconv(text)}
      rescue Errno::EINVAL, Iconv::IllegalSequence
        # Replace with the entire matched encoded word, a NOOP.
        text = word
      end
    end
  end
end

