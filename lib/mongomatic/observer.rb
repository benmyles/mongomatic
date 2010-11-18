module Mongomatic
  class Observer
    class << self
      
      def subclasses
        @subclasses || []
      end
      
      def inherited(subclass)
        if (subclass_as_string = subclass.to_s) =~ /Observer$/
          observable = Object.const_get(subclass.to_s.gsub('Observer', ''))
          observable.add_observer(subclass)
        end
      rescue NameError
        # Can't autoadd observer
      ensure
        @subclasses ||= []
        @subclasses << subclass
      end
    end
  end
end