module Mongomatic
  class Base
    include Mongomatic::Modifiers
    include Mongomatic::Util
    include Mongomatic::ActiveModelCompliancy
    include Mongomatic::TypedFields
    
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
        do_callback(:before_drop)
        collection.drop
        do_callback(:after_drop)
      end
      
      def do_callback(meth)
        return false unless respond_to?(meth, true)
        send(meth)
      end
    end

    attr_accessor :removed, :is_new, :errors

    def initialize(doc_hash=Mongomatic::MHash.new, is_new=true)
      self.doc = doc_hash
      self.removed = false
      self.is_new  = is_new
      self.errors  = Mongomatic::Errors.new
      do_callback(:after_initialize)
    end
    
    def doc=(hash)
      hash = Mongomatic::MHash.new(hash) unless hash.is_a?(Mongomatic::MHash)
      @doc = hash
    end
    
    def doc
      @doc
    end
    
    # Override this with your own validate() method for validations.
    # Simply push your errors into the self.errors property and
    # if self.errors remains empty your document will be valid.
    #  def validate
    #    self.errors.add "name", "cannot be blank"
    #  end
    def validate
      true
    end
    
    def valid?
      check_typed_fields!
      self.errors = Mongomatic::Errors.new
      do_callback(:before_validate)
      validate
      do_callback(:after_validate)
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
    
    # Returns true if document contains key
    def has_key?(key)
      field, hash = hash_for_field(key.to_s, true)
      hash.has_key?(field)
    end
    
    def set_value_for_key(key, value)
      field, hash = hash_for_field(key.to_s)
      hash[field] = value
    end
    
    def value_for_key(key)
      field, hash = hash_for_field(key.to_s, true)
      hash[field]
    end
   
    ##
    # Same as Hash#delete
    #
    # mydoc.delete("name")
    #  => "Ben"
    # mydoc.has_hey?("name")
    #  => false
    def delete(key)
      @doc.delete(key)
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
        self.doc = obj.doc; true
      end
    end

    # Insert the document into the database. Will return false if the document has
    # already been inserted or is invalid. Returns the generated BSON::ObjectId
    # for the new document. Will silently fail if MongoDB is unable to insert the
    # document, use insert! or send in {:safe => true} if you want a Mongo::OperationError.
    # If you want to raise the following errors also, pass in {:raise => true}
    #   * Raises Mongomatic::Exceptions::DocumentNotNew if document is not new
    #   * Raises Mongomatic::Exceptions::DocumentNotValid if there are validation errors
    def insert(opts={})
      if opts[:raise] == true
        raise Mongomatic::Exceptions::DocumentWasRemoved if removed?
        raise Mongomatic::Exceptions::DocumentNotNew unless new?
        raise Mongomatic::Exceptions::DocumentNotValid unless valid?
      else
        return false unless new? && valid?
      end

      do_callback(:before_insert)
      do_callback(:before_insert_or_update)
      if ret = self.class.collection.insert(@doc,opts)
        @doc["_id"] = @doc.delete(:_id) if @doc[:_id]
        self.is_new = false
      end
      do_callback(:after_insert)
      do_callback(:after_insert_or_update)
      ret
    end
    
    # Calls insert(...) with {:safe => true} passed in as an option. 
    #   * Raises Mongo::OperationError if there was a DB error on inserting
    # If you want to raise the following errors also, pass in {:raise => true}
    #   * Raises Mongomatic::Exceptions::DocumentNotNew if document is not new
    #   * Raises Mongomatic::Exceptions::DocumentNotValid if there are validation errors
    def insert!(opts={})
      insert(opts.merge(:safe => true))
    end
    
    # Will persist any changes you have made to the document. Silently fails on
    # db update error. Use update! or pass in {:safe => true} to raise a
    # Mongo::OperationError if that's what you want.
    # If you want to raise the following errors also, pass in {:raise => true}
    #   * Raises Mongomatic::Exceptions::DocumentIsNew if document is new
    #   * Raises Mongomatic::Exceptions::DocumentNotValid if there are validation errors
    #   * Raises Mongomatic::Exceptions::DocumentWasRemoved if document has been removed
    def update(opts={},update_doc=@doc)
      if opts[:raise] == true
        raise Mongomatic::Exceptions::DocumentWasRemoved if removed?
        raise Mongomatic::Exceptions::DocumentIsNew      if new?
        raise Mongomatic::Exceptions::DocumentNotValid   unless valid?
      else
        return false if new? || removed? || !valid?
      end
      do_callback(:before_update)
      do_callback(:before_insert_or_update)
      ret = self.class.collection.update({"_id" => @doc["_id"]}, update_doc, opts)
      do_callback(:after_update)
      do_callback(:after_insert_or_update)
      ret
    end
    
    # Calls update(...) with {:safe => true} passed in as an option. 
    #   * Raises Mongo::OperationError if there was a DB error on updating
    # If you want to raise the following errors also, pass in {:raise => true}
    #   * Raises Mongomatic::Exceptions::DocumentIsNew if document is new
    #   * Raises Mongomatic::Exceptions::DocumentNotValid if there are validation errors
    #   * Raises Mongomatic::Exceptions::DocumentWasRemoved if document has been removed
    def update!(opts={},update_doc=@doc)
      update(opts.merge(:safe => true),update_doc)
    end
    
    # Remove this document from the collection. Silently fails on db error,
    # use remove! or pass in {:safe => true} if you want an exception raised.
    # If you want to raise the following errors also, pass in {:raise => true}
    #   * Raises Mongomatic::Exceptions::DocumentIsNew if document is new
    #   * Raises Mongomatic::Exceptions::DocumentWasRemoved if document has been already removed
    def remove(opts={})
      if opts[:raise] == true
        raise Mongomatic::Exceptions::DocumentWasRemoved if removed?
        raise Mongomatic::Exceptions::DocumentIsNew      if new?
      else
        return false if new? || removed?
      end
      do_callback(:before_remove)
      if ret = self.class.collection.remove({"_id" => @doc["_id"]})
        self.removed = true; freeze; ret
      end
      do_callback(:after_remove)
      ret
    end
    
    # Calls remove(...) with {:safe => true} passed in as an option. 
    #   * Raises Mongo::OperationError if there was a DB error on removing
    # If you want to raise the following errors also, pass in {:raise => true}
    #   * Raises Mongomatic::Exceptions::DocumentIsNew if document is new
    #   * Raises Mongomatic::Exceptions::DocumentWasRemoved if document has been already removed
    def remove!(opts={})
      remove(opts.merge(:safe => true))
    end
    
    # Return this document as a hash.
    def to_hash
      @doc || {}
    end
    
    def hash_for_field(field, break_if_dne=false)
      parts = field.split(".")
      curr_hash = self.doc
      return [parts[0], curr_hash] if parts.size == 1
      field = parts.pop # last one is the field
      parts.each_with_index do |part, i|
        return [part, curr_hash] if break_if_dne && !curr_hash.has_key?(part)
        curr_hash[part] ||= {}
        return [field, curr_hash[part]] if parts.size == i+1
        curr_hash = curr_hash[part]
      end
    end
    
    def do_callback(meth)
      return false unless respond_to?(meth, true)
      send(meth)
    end
    
    def transaction(key=nil, duration=5, &block)
      raise Mongomatic::Exceptions::DocumentIsNew if new?
      key ||= [self.class.name, self["_id"].to_s].join("-")
      TransactionLock.start(key, duration, &block)
    end
  end
end
