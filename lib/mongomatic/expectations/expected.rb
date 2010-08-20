module Mongomatic
  module Expectations
    class Expected < Expectation
      def self.name
        "expected"
      end
      
      def to_be
        case value
        when Proc
          add_error_msg unless value.call
        when Symbol
          add_error_msg unless instance.send(value)
        else
          add_error_msg unless value
        end
      end

      def to_not_be
        case value
        when Proc
          add_error_msg if value.call
        when Symbol
          add_error_msg if instance.send(value)
        else
          add_error_msg if value
        end
      end
    end
  end
end