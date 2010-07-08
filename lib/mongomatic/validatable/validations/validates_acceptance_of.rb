module Mongomatic
  module Validatable
    class ValidatesAcceptanceOf < ValidationBase #:nodoc:    
      def valid?(instance)
        value = instance[self.attribute.to_s]
        return true if allow_nil && value.nil?
        return true if allow_blank && value.blank?
        %w(1 true t).include?(value)
      end
    
      def message(instance)
        super || "must be accepted"
      end
    end
  end
end