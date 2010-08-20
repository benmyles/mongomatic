module Mongomatic
  # Wraps a Mongo::Cursor for managing result sets from MongoDB:
  #  cursor = User.find({"zip" => 94107})
  #  user1 = cursor.next
  #
  #  User.find({"zip" => 94107}).each { |u| puts u["name"] }
  #
  #  User.find({"zip" => 94107}).count
  class Cursor
    include Enumerable
    
    attr_accessor :mongo_cursor
    
    def initialize(obj_class, mongo_cursor)
      @obj_class    = obj_class
      @mongo_cursor = mongo_cursor
      
      @mongo_cursor.public_methods(false).each do |meth|
        next if self.methods.collect { |meth| meth.to_sym }.include?(meth.to_sym)
        (class << self; self; end).class_eval do
          define_method meth do |*args|
            @mongo_cursor.send meth, *args
          end
        end
      end
    end
    
    # Is the cursor empty? This method is much more efficient than doing cursor.count == 0
    def empty?
      @mongo_cursor.has_next? == false
    end
    
    def next_document
      if doc = @mongo_cursor.next_document
        @obj_class.new(doc, false)
      end
    end
    
    alias :next :next_document
    
    def each
      @mongo_cursor.each do |doc|
        yield(@obj_class.new(doc, false))
      end
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