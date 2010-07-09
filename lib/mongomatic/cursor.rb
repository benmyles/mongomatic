module Mongomatic
  class Cursor
    attr_accessor :mongo_cursor
    
    def initialize(obj_class, mongo_cursor)
      @obj_class    = obj_class
      @mongo_cursor = mongo_cursor
      
      @mongo_cursor.public_methods(false).each do |meth|
        next if self.methods.include?(meth.to_sym)
        (class << self; self; end).class_eval do
          define_method meth do |*args|
            @mongo_cursor.send meth, *args
          end
        end
      end
    end
    
    def next_document
      if doc = @mongo_cursor.next_document
        @obj_class.new(doc)
      end
    end
    
    alias :next :next_document
    
    def each
      @mongo_cursor.each do |doc|
        yield(@obj_class.new(doc))
      end
    end
    
    def to_a
      @mongo_cursor.to_a.collect { |doc| @obj_class.new(doc) }
    end
    
    def current_limit
      @mongo_cursor.limit
    end
    
    def limit(number_to_return)
      @mongo_cursor.limit(number_to_return); self
    end
    
    def current_skip
      @mongo_cursor.skip
    end
    
    def skip(number_to_skip)
      @mongo_cursor.skip(number_to_skip); self
    end
    
    def sort(key_or_list, direction = nil)
      @mongo_cursor.sort(key_or_list, direction); self
    end
  end
end