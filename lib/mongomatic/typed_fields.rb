module Mongomatic
  # = Typed Fields
  # Explicitly specify the field types in your document. This is completely optional.
  # You can also set whether or not we should try to automatically cast a type to the
  # desired type.
  # = Examples
  #   typed_field "age",                :type => :integer, :cast => true
  #   typed_field "manufacturer.name",  :type => :string,  :cast => false
  module TypedFields
    class InvalidType < RuntimeError; end
    
    KNOWN_TYPES = [:string, :integer, :float]
    
    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
    end
    
    module ClassMethods
      def typed_field(name, opts)
        unless Mongomatic::TypedFields::KNOWN_TYPES.include?(opts[:type])
          raise Mongomatic::TypedFields::Invalidtype, "#{opts[:type]}"
        end
        
        opts = {:cast => true}.merge(opts)

        @typed_fields ||= {}
        @typed_fields[name] = opts
      end
      
      def typed_fields
        @typed_fields || {}
      end
    end # ClassMethods
    
    module InstanceMethods

      def check_typed_fields!
        self.class.typed_fields.each do |name, opts|
          cast_or_raise_typed_field(name, opts)
        end
      end
      
      def cast_or_raise_typed_field(name, opts)
        val      = value_for_key(name.to_s); return if val.nil?
        type     = opts[:type].to_sym
        try_cast = opts[:cast]
        
        case type
        when :string then
          return val if val.is_a?(String)
          return set_value_for_key(name, val.to_s) if try_cast && val.respond_to?(:to_s)
        when :integer then
          return val if val.is_a?(Fixnum)
          return set_value_for_key(name, val.to_i) if try_cast && val.respond_to?(:to_i)
        when :float then
          return val if val.is_a?(Float)
          return set_value_for_key(name, val.to_f) if try_cast && val.respond_to?(:to_f)
        end
        
        raise InvalidType, "#{name} should be a :#{type}"
      end
      
    end # InstanceMethods
  end # TypedFields
end # Mongomatic