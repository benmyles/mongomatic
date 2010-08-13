module Mongomatic
  class Base
    include Mongomatic::Modifiers
    
    class << self
      def db
        @db || Mongomatic.db || raise(ArgumentError, "No db supplied")
      end
      
      def db=(obj)
        unless obj.is_a?(Mongo::DB)
          raise(ArgumentError, "Must supply a Mongo::DB object")
        end; @db = obj
      end

      def collection_name
        self.to_s
      end

      def collection
        @collection ||= self.db.collection(self.collection_name)
      end

      def find(query={}, opts={})
        Mongomatic::Cursor.new(self, collection.find(query, opts))
      end
      
      def find_one(query={}, opts={})
        return nil unless doc = self.collection.find_one(query, opts)
        self.new(doc, false)
      end
      
      def all
        find
      end
      
      def each
        find.each { |found| yield(found) }
      end
      
      def first
        find.limit(1).next_document
      end
      
      def count
        find.count
      end
    end

    attr_accessor :removed, :is_new, :errors

    def initialize(doc={}, is_new=true)
      @doc = doc.stringify_keys
      self.removed = false
      self.is_new  = is_new
      self.errors  = Mongomatic::Errors.new
    end
    
    def validate
      true
    end
    
    def valid?
      self.errors = Mongomatic::Errors.new
      self.send(:before_validate) if self.respond_to?(:before_validate)
      validate
      self.send(:after_validate) if self.respond_to?(:after_validate)
      self.errors.empty?
    end
    
    def is_new?
      self.is_new == true
    end
    
    def new?
      self.is_new == true
    end
    
    def []=(k,v)
      @doc[k.to_s] = v
    end
    
    def [](k)
      @doc[k.to_s]
    end
    
    def merge(hash)
      hash.each { |k,v| self[k] = v }; @doc
    end
    
    def removed?
      self.removed == true
    end
    
    def ==(obj)
      obj.is_a?(self.class) && obj.doc["_id"] == @doc["_id"]
    end

    def reload
      if obj = self.class.find({"_id" => @doc["_id"]}).next_document
        @doc = obj.doc; true
      end
    end

    def insert(opts={})
      return false unless new? && valid?
      self.send(:before_insert) if self.respond_to?(:before_insert)
      self.send(:before_insert_or_update) if self.respond_to?(:before_insert_or_update)
      if ret = self.class.collection.insert(@doc,opts)
        @doc["_id"] = @doc.delete(:_id) if @doc[:_id]
        self.is_new = false
      end
      self.send(:after_insert) if self.respond_to?(:after_insert)
      self.send(:after_insert_or_update) if self.respond_to?(:after_insert_or_update)
      ret
    end
    
    def insert!(opts={})
      insert(opts.merge(:safe => true))
    end
    
    def update(opts={},update_doc=@doc)
      return false if new? || removed? || !valid?
      self.send(:before_update) if self.respond_to?(:before_update)
      self.send(:before_insert_or_update) if self.respond_to?(:before_insert_or_update)
      ret = self.class.collection.update({"_id" => @doc["_id"]}, update_doc, opts)
      self.send(:after_update) if self.respond_to?(:after_update)
      self.send(:after_insert_or_update) if self.respond_to?(:after_insert_or_update)
      ret
    end
    
    def update!(opts={},update_doc=@doc)
      update(opts.merge(:safe => true),update_doc)
    end
    
    def remove(opts={})
      return false if new?
      self.send(:before_remove) if self.respond_to?(:before_remove)
      if ret = self.class.collection.remove({"_id" => @doc["_id"]})
        self.removed = true; freeze; ret
      end
      self.send(:after_remove) if self.respond_to?(:after_remove)
      ret
    end
    
    def remove!(opts={})
      remove(opts.merge(:safe => true))
    end
    
    def to_hash
      @doc || {}
    end
    
    protected
    
    def doc
      @doc
    end
    
    def doc=(v)
      @doc = v
    end
  end
end