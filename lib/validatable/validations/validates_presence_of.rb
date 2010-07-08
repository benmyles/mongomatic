module Validatable 
  class ValidatesPresenceOf < ValidationBase #:nodoc:
    def valid?(instance)
      value = instance[self.attribute.to_s]
      return true if allow_nil && value.nil?
      return true if allow_blank && value.blank?
      
      return false if instance[self.attribute.to_s].nil?
      value.respond_to?(:strip) ? instance[self.attribute.to_s].strip.length != 0 : true
    end
    
    def message(instance)
      super || "can't be empty"
    end
  end
end

