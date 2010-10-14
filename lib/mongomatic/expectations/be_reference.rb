module Mongomatic
  module Expectations
    class BeReference < Expectation
      def self.name
        "reference"
      end
  
      def to_be
        return true if opts[:allow_nil] && value.nil?
    
        add_error_msg unless value.is_a? BSON::ObjectId
      end
    end
  end
end