module Mongomatic
  class Base
    include Mongomatic::Modifiers
    
    class << self
      # Returns this models own db attribute if set, otherwise will return Mongomatic.db
      def db
        @db || Mongomatic.db || raise(ArgumentError, "No db supplied")
      end
      
      # Override Mongomatic.db with a Mongo::DB instance for this model specifically
      #  MyModel.db = Mongo::Connection.new().db('mydb_mymodel')
      def db=(obj)
        unless obj.is_a?(Mongo::DB)
          raise(ArgumentError, "Must supply a Mongo::DB object")
        end; @db = obj
      end

      # Override this method on your model if you want to use a different collection name
      def collection_name
        self.to_s
      end

      # Return the raw MongoDB collection for this model
      def collection
        @collection ||= self.db.collection(self.collection_name)
      end

      # Query MongoDB for documents. Same arguments as http://api.mongodb.org/ruby/current/Mongo/Collection.html#find-instance_method
      def find(query={}, opts={})
        Mongomatic::Cursor.new(self, collection.find(query, opts))
      end
      
      # Query MongoDB and return one document only. Same arguments as http://api.mongodb.org/ruby/current/Mongo/Collection.html#find_one-instance_method
      def find_one(query={}, opts={})
        return nil unless doc = self.collection.find_one(query, opts)
        self.new(doc, false)
      end
      
      # Return a Mongomatic::Cursor instance of all documents in the collection.
      def all
        find
      end
      
      # Iterate over all documents in the collection (uses a Mongomatic::Cursor)
      def each
        find.each { |found| yield(found) }
      end
      
      # Return the first document in the collection
      def first
        find.limit(1).next_document
      end
      
      # Is the collection empty? This method is much more efficient than doing Collection.count == 0
      def empty?
        find.limit(1).has_next? == false
      end
      
      # Return the number of documents in the collection
      def count
        find.count
      end

      def drop
        self.send(:before_drop) if self.respond_to?(:before_drop)
        collection.drop
        self.send(:after_drop) if self.respond_to?(:after_drop)
      end
    end

    attr_accessor :removed, :is_new, :errors

    def initialize(doc={}, is_new=true)
      @doc = doc.stringify_keys
      self.removed = false
      self.is_new  = is_new
      self.errors  = Mongomatic::Errors.new
    end
    
    # Override this with your own validate() method for validations.
    # Simply push your errors into the self.errors property and
    # if self.errors remains empty your document will be valid.
    #  def validate
    #    self.errors << ["name", "cannot be blank"]
    #  end
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
    
    # Set a field on this document:
    #  mydoc["name"] = "Ben"
    #  mydoc["address"] = { "city" => "San Francisco" }
    def []=(k,v)
      @doc[k.to_s] = v
    end
    
    # Fetch a field (just like a hash):
    #  mydoc["name"]
    #   => "Ben"
    def [](k)
      @doc[k.to_s]
    end
    
    # Merge this document with the supplied hash. Useful for updates:
    #  mydoc.merge(params[:user])
    def merge(hash)
      hash.each { |k,v| self[k] = v }; @doc
    end
    
    # Will return true if the document has been removed.
    def removed?
      self.removed == true
    end
    
    # Check equality with another Mongomatic document
    def ==(obj)
      obj.is_a?(self.class) && obj.doc["_id"] == @doc["_id"]
    end

    # Reload the document from the database
    def reload
      if obj = self.class.find({"_id" => @doc["_id"]}).next_document
        @doc = obj.doc; true
      end
    end

    # Insert the document into the database. Will return false if the document has
    # already been inserted or is invalid. Returns the generated BSON::ObjectID
    # for the new document. Will silently fail if MongoDB is unable to insert the
    # document, use insert! if you want an error raised instead. Note that this will
    # require an additional call to the db.
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
    
    # Calls insert(...) with {:safe => true} passed in as an option. Will check MongoDB
    # after insert to make sure that the insert was successful, and raise a Mongo::OperationError
    # if there were any problems.
    def insert!(opts={})
      insert(opts.merge(:safe => true))
    end
    
    # Will persist any changes you have made to the document. Will silently fail if
    # MongoDB is unable to update the document, use update! instead if you want an
    # error raised. Note that this will require an additional call to the db.
    def update(opts={},update_doc=@doc)
      return false if new? || removed? || !valid?
      self.send(:before_update) if self.respond_to?(:before_update)
      self.send(:before_insert_or_update) if self.respond_to?(:before_insert_or_update)
      ret = self.class.collection.update({"_id" => @doc["_id"]}, update_doc, opts)
      self.send(:after_update) if self.respond_to?(:after_update)
      self.send(:after_insert_or_update) if self.respond_to?(:after_insert_or_update)
      ret
    end
    
    # Same as update(...) but will raise a Mongo::OperationError in case of any issues.
    def update!(opts={},update_doc=@doc)
      update(opts.merge(:safe => true),update_doc)
    end
    
    # Remove this document from the collection. Silently fails on error, use remove!
    # if you want an exception raised.
    def remove(opts={})
      return false if new?
      self.send(:before_remove) if self.respond_to?(:before_remove)
      if ret = self.class.collection.remove({"_id" => @doc["_id"]})
        self.removed = true; freeze; ret
      end
      self.send(:after_remove) if self.respond_to?(:after_remove)
      ret
    end
    
    # Like remove(...) but raises Mongo::OperationError if MongoDB is unable to
    # remove the document.
    def remove!(opts={})
      remove(opts.merge(:safe => true))
    end
    
    # Return this document as a hash.
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
