module Mongomatic

  class TransactionLock < Base
    def self.create_indexes
      collection.create_index("key", :unique => true, :drop_dups => true)
      collection.create_index("expire_at")
    end
    
    def self.start(key, duration, &block)
      lock = new(:key => key, :expire_at => Time.now.utc + duration)
      
      # we need to get a lock
      begin
        lock.insert!
      rescue Mongo::OperationFailure => e
        remove_stale_locks
        if find_one(:key => key) == nil
          return start(key, duration, &block)
        end
        raise Mongomatic::Exceptions::CannotGetTransactionLock
      end
      
      begin
        block.call
      ensure
        lock.remove
      end
    end
    
    def self.remove_stale_locks
      collection.remove({:expire_at => {"$lte" => Time.now.utc}}, {:safe => true})
    end
  end
  
end