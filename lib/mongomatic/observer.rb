module Mongomatic
  class Observer
    class << self
      
      def subclasses
        @subclasses || []
      end
      
      def inherited(subclass)
        if (subclass_as_string = subclass.to_s) =~ /Observer$/
          observable = Object.const_get(subclass_as_string.gsub('Observer', ''))
          observable.add_observer(subclass)
        end
      rescue NameError, NoMethodError
        # Can't autoadd observer
      ensure
        @subclasses ||= []
        @subclasses << subclass
      end
    end
  end
end