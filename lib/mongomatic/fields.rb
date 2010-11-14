module Mongomatic
  # You can specify the fields available on your document using "field".
  # This is entirely optional, but suggested as it will lead to better
  # documenting code. You also get some free features including automatic
  # type casting and/or checking.
  module Fields
    class InvalidField < RuntimeError; end
    
    KNOWN_TYPES = [:string, :integer, :float]
    
    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
    end
    
    module ClassMethods
      def field(name, opts)
        unless Mongomatic::Fields::KNOWN_TYPES.include?(opts[:type])
          raise(ArgumentError, "invalid :type")
        end
        
        opts = {:cast => true, :raise => false}.merge(opts)

        @fields ||= {}
        @fields[name] = opts
      end
      
      def fields
        @fields || {}
      end
    end # ClassMethods
    
    module InstanceMethods

      def check_fields!
        self.class.fields.each do |name, opts|
          val = value_for_key(name.to_s)
          next if val.nil?
          case opts[:type]
          when :string then
            unless val.is_a?(String)
              raise(InvalidField, "#{name} should be a :string") if opts[:raise]
              set_value_for_key(name, val.to_s) if opts[:cast]
            end
          when :integer then
            unless val.is_a?(Fixnum)
              raise(InvalidField, "#{name} should be a :integer") if opts[:raise]
              set_value_for_key(name, val.to_i) if opts[:cast]
            end
          when :float then
            unless val.is_a?(Float)
              raise(InvalidField, "#{name} should be a :float") if opts[:raise]
              set_value_for_key(name, val.to_f) if opts[:cast]
            end
          else
            raise "unknown :type"
          end # case
        end
      end # fields!
      
    end # InstanceMethods
  end # Fields
end # Mongomatic