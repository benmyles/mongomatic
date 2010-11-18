module Mongomatic
  module Observable
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
    
    def notify(meth)
      self.class.observers.each do |observer|
        @observer_cache ||= {}
        unless observer_klass = @observer_cache[observer]
          @observer_cache[observer] = observer_klass = Object.const_get(observer) if Module.const_defined?(observer)
        end
        instance = observer_klass.new
        instance.send(meth, self) if instance.respond_to?(meth)
      end
    end
    
    module ClassMethods
      def observers
        @observers ||= []
      end
      
      def add_observer(klass)
        @observers ||= []
        @observers << klass.to_s.to_sym unless @observers.include?(klass.to_s.to_sym)
      end
      alias :observer :add_observer
      
      def has_observer?(klass_or_sym)
        case klass_or_sym
        when Symbol
          @observers.include?(klass)
        else
          @observers.include?(klass.to_s.to_sym)
        end
      end
      
      def remove_observers
        @observers = []
      end
    end
  end
end