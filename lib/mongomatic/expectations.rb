module Mongomatic
  module Expectations
    module Helper
      
      private
      
      def define_expectations
        Mongomatic::Expectations::Expectation.subclasses.each do |klass|
          if klass.new(nil, nil, nil).respond_to? :to_be
            instance_eval %Q{
              def be_#{klass.name.downcase}(value, message, opts = {})
                #{klass}.new(self, value, message, opts).to_be
              end
            }
          end
          if klass.new(nil, nil, nil).respond_to? :to_not_be
            instance_eval %Q{
              def not_be_#{klass.name.downcase}(value, message, opts = {})
                #{klass}.new(self, value, message, opts).to_not_be
              end
            }
          end
          
        end
      end
      
      def undefine_expectations
        Mongomatic::Expectations::Expectation.subclasses.each do |klass|
          instance_eval %Q{
            if respond_to? "be_#{klass.name.downcase}"
              class << self
                remove_method "be_#{klass.name.downcase}" 
              end
            end
            if respond_to? "not_be_#{klass.name.downcase}"
              class << self
                remove_method "not_be_#{klass.name.downcase}" 
              end
            end
          }
        end
      end
      
      def expectations(&block)
        define_expectations
        block.call
        undefine_expectations
      end 
    end
    
    class Expectation
      
      attr_accessor :instance, :value, :message, :opts
      
      class << self
        attr_accessor :subclasses
        
        def subclasses
          @subclasses ||= []
          @subclasses
        end
        
        def inherited(klass)
          subclasses << klass
        end
      end
      
      def initialize(instance, value, message, opts = {})
        @value = value
        @instance = instance
        @message = message
        @opts = opts
      end
      
      def add_error_msg
        instance.errors << [message]
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/expectations/*.rb"].each { |f| require f }