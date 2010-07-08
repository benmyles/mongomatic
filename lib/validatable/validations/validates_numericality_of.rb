module Validatable 
  class ValidatesNumericalityOf < ValidationBase #:nodoc:
    option :only_integer
    
    def valid?(instance)
      value = value_for(instance)
      return true if allow_nil && value.nil?
      return true if allow_blank && value.blank?
      
      value = value.to_s
      regex = self.only_integer ? /\A[+-]?\d+\Z/ : /^\d*\.{0,1}\d+$/
      not (value =~ regex).nil?
    end
    
    def message(instance)
      super || "must be a number"
    end
    
    private
      def value_for(instance)
        before_typecast_method = "#{self.attribute}_before_typecast"
        value_method = instance.respond_to?(before_typecast_method.intern) ? before_typecast_method : self.attribute
        instance.send(value_method)
      end
  end
end

