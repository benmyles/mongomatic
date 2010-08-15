module Mongomatic 
  module Expectations
    class Match < Expectation
      def self.name
        "match"
      end
  
      def to_be
        return true if opts[:allow_nil] && value.nil?
    
        add_error_msg unless opts[:with].match(value.to_s)
      end
  
      def to_not_be
        add_error_msg if opts[:with].match(value.to_s)
      end
    end
  end
end