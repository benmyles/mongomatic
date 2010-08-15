module Mongomatic
  module Expectations
    class IsNumber < Expectation
      def self.name
        "a_number"
      end
  
      def to_be
        return true if opts[:allow_nil] && value.nil?
    
        add_error_msg if (value.to_s =~ /^\d*\.{0,1}\d+$/).nil?
      end
  
      def to_not_be
        add_error_msg unless (value.to_s =~ /^\d*\.{0,1}\d+$/).nil?
      end
    end
  end
end