module Mongomatic
  module Expectations
    class Present < Expectation
      def self.name
        "present"
      end
      
      def to_be
        add_error_msg if value.blank?
      end
  
      def to_not_be
        add_error_msg unless value.blank?
      end
    end
  end
end