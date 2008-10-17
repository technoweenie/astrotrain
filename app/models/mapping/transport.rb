class Mapping
  class Transport
    class << self
      attr_accessor :processing
    end
    self.processing = false

    attr_reader :message, :mapping
    def self.process(message, mapping)
      new(message, mapping).process
    end

    def initialize(message, mapping)
      @message = message
      @mapping = mapping
    end

    def process
    end
  end
end