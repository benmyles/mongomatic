module Validatable
  class ValidatesConfirmationOf < ValidationBase #:nodoc:
    option :case_sensitive
    default :case_sensitive => true
    
    def initialize(klass, attribute, options={})
      klass.class_eval { attr_accessor "#{attribute}_confirmation" }
      super
    end
    
    def valid?(instance)
      confirmation_value = instance.send("#{self.attribute}_confirmation")
      return true if allow_nil && confirmation_value.nil?
      return true if allow_blank && confirmation_value.blank?
      return instance[self.attribute.to_s] == instance.send("#{self.attribute}_confirmation".to_sym) if case_sensitive
      instance[self.attribute.to_s].to_s.casecmp(instance.send("#{self.attribute}_confirmation".to_sym).to_s) == 0
    end
    
    def message(instance)
      super || "doesn't match confirmation"
    end
  end
end