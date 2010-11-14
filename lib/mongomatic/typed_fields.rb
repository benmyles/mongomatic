module Mongomatic
  # = Typed Fields
  # Lets you specify the type that fields in your document should
  # be, and either try to automatically cast to that type or raise
  # an exception if the type is not what was expected.
  # = Examples
  #   typed_field "age",                :type => :integer, :cast => true,  :raise => false
  #   typed_field "manufacturer.name",  :type => :string,  :cast => false, :raise => true
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
        
        opts = {:cast => true, :raise => false}.merge(opts)

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
          val = value_for_key(name.to_s)
          next if val.nil?
          case opts[:type]
          when :string then
            unless val.is_a?(String)
              raise(InvalidType, "#{name} should be a :string") if opts[:raise]
              set_value_for_key(name, val.to_s) if opts[:cast]
            end
          when :integer then
            unless val.is_a?(Fixnum)
              raise(InvalidType, "#{name} should be a :integer") if opts[:raise]
              set_value_for_key(name, val.to_i) if opts[:cast]
            end
          when :float then
            unless val.is_a?(Float)
              raise(InvalidType, "#{name} should be a :float") if opts[:raise]
              set_value_for_key(name, val.to_f) if opts[:cast]
            end
          else
            raise "unknown :type"
          end # case
        end
      end # check_typed_fields!
      
    end # InstanceMethods
  end # TypedFields
end # Mongomatic