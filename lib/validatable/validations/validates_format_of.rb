module Validatable
  class ValidatesFormatOf < ValidationBase #:nodoc:
    required_option :with
  
    def valid?(instance)
      value = instance[self.attribute.to_s]
      return true if allow_nil && value.nil?
      return true if allow_blank && value.blank?
      not (value.to_s =~ self.with).nil?
    end
    
    def message(instance)
      super || "is invalid"
    end
  end
end