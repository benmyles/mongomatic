module Mongomatic
  # = Typed Fields
  # Explicitly specify the field types in your document. This is completely optional.
  # You can also set whether or not we should try to automatically cast a type to the
  # desired type.
  # = Examples
  #   typed_field "age",                :type => :fixnum,  :cast => true
  #   typed_field "manufacturer.name",  :type => :string,  :cast => false
  module TypedFields
    class InvalidType < RuntimeError; end
    
    KNOWN_TYPES = [:string, :float, :fixnum, :array, :hash, :bool,
                   :time, :regex, :symbol, :object_id]
    
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
        
        converter = Mongomatic::TypeConverters.for_type(type).new(val)
        return true if converter.type_match?
        raise(InvalidType, "#{name} should be a :#{type}") unless try_cast
        set_value_for_key(name, converter.cast)
      end
      
    end # InstanceMethods
  end # TypedFields
end # Mongomatic