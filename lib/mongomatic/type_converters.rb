module Mongomatic
  module TypeConverters
    class CannotCastValue < RuntimeError; end
    
    def self.for_type(type)
      eval "Mongomatic::TypeConverters::#{type.to_s.camelize}"
    end
    
    class Base
      def initialize(orig_val)
        @orig_val = orig_val
      end
      
      def type_match?
        raise "abstract"
      end
      
      def cast
        if type_match?
          @orig_val
        else
          convert_orig_val || raise(CannotCastValue)
        end
      end
      
      def convert_orig_val
        raise "abstract"
      end
    end
    
    class String < Base
      def type_match?
        @orig_val.class.to_s == "String"
      end
      
      def convert_orig_val
        @orig_val.respond_to?(:to_s) ? @orig_val.to_s : nil
      end
    end
    
    class Float < Base
      def type_match?
        @orig_val.class.to_s == "Float"
      end
      
      def convert_orig_val
        @orig_val.respond_to?(:to_f) ? @orig_val.to_f : nil
      end
    end
    
    class Fixnum < Base
      def type_match?
        @orig_val.class.to_s == "Fixnum"
      end
      
      def convert_orig_val
        @orig_val.respond_to?(:to_i) ? @orig_val.to_i : nil
      end
    end
    
    class Array < Base
      def type_match?
        @orig_val.class.to_s == "Array"
      end
      
      def convert_orig_val
        @orig_val.respond_to?(:to_a) ? @orig_val.to_a : nil
      end
    end

    class Hash < Base
      def type_match?
        @orig_val.class.to_s == "Hash"
      end
      
      def convert_orig_val
        [:to_h, :to_hash].each do |meth|
          res = (@orig_val.respond_to?(meth) ? @orig_val.send(meth) : nil)
          return res if !res.nil?
        end; nil
      end
    end

    class Bool < Base
      def type_match?
        @orig_val == true || @orig_val == false
      end
      
      def convert_orig_val
        s_val = @orig_val.to_s.downcase
        if %w(1 t true y yes).include?(s_val)
          true
        elsif %w(0 f false n no).include?(s_val)
          false
        else
          nil
        end
      end
    end
        
    class Time < Base
      def type_match?
        @orig_val.class.to_s == "Time"
      end

      def convert_orig_val
        Time.parse(@orig_val.to_s)
      rescue ArgumentError => e
        nil
      end
    end
    
    class Regex < Base
      def type_match?
        @orig_val.class.to_s == "Regexp"
      end
      
      def convert_orig_val
        Regexp.new(@orig_val.to_s)
      end
    end
    
    class Symbol < Base
      def type_match?
        @orig_val.class.to_s == "Symbol"
      end
      
      def convert_orig_val
        @orig_val.respond_to?(:to_sym) ? @orig_val.to_sym : nil
      end
    end
    
    class ObjectId < Base
      def type_match?
        @orig_val.class.to_s == "BSON::ObjectId"
      end
      
      def convert_orig_val
        BSON::ObjectId(@orig_val.to_s)
      rescue BSON::InvalidObjectId => e
        nil
      end
    end
    
  end
end