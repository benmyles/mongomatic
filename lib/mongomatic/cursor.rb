module Mongomatic
  class Cursor
    attr_accessor :mongo_cursor
    
    def initialize(obj_class, mongo_cursor)
      @obj_class    = obj_class
      @mongo_cursor = mongo_cursor
      
      @mongo_cursor.public_methods(false).each do |meth|
        next if ["next_document","each","to_a"].include?(meth.to_s)
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
  end
end