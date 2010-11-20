module Mongomatic
  # Provides convenience methods for atomic MongoDB operations.
  module Modifiers

    class UnexpectedFieldType < RuntimeError; end
    
    def start_modifier_chain
      # add while(:flushing) check here?
      @modifier_state = :chain
      @modifier_buffer = {}
      
      if block_given?
        yield(self)
        flush_modifier_chain
      end
      
      self
    end
    
    def flush_modifier_chain
      @modifier_state = :flush
      op, update_opts = prepare_modifier_flush(@modifier_buffer)
      update(update_opts, op)
      reload
      @modifier_state = nil
    end
    
    # MongoDB equivalent: { $push : { field : value } }<br/>
    # Appends value to field, if field is an existing array, otherwise sets field to the array [value] 
    # if field is not present. If field is present but is not an array, error is returned.
    def push(field, val, update_opts={}, safe=false)
      send(get_modifier_meth(:push), field, val, update_opts, safe)
    end
    
    def push!(field, val, update_opts={})
      push(field, val, update_opts, true)
    end

    # MongoDB equivalent: { $pushAll : { field : value_array } }<br/>
    # Appends each value in value_array to field, if field is an existing array, otherwise sets field to 
    # the array value_array if field is not present. If field is present but is not an array, an error 
    # condition is raised.
    #  user.push("interests", ["skydiving", "coding"])
    def push_all(field, val, update_opts={}, safe=false)
      send(get_modifier_meth(:push_all), field, val, update_opts, safe)
    end
    
    def push_all!(field, val, update_opts={})
      push_all(field, val, update_opts, true)
    end
    
    # MongoDB equivalent: { $pull : { field : _value } }<br/>
    # Removes all occurrences of value from field, if field is an array. If field is present but is not 
    # an array, an error condition is raised.
    #  user.pull("interests", "watching paint dry")
    def pull(field, val, update_opts={}, safe=false)
      send(get_modifier_meth(:pull), field, val, update_opts, safe)
    end
    
    def pull!(field, val, update_opts={})
      pull(field, val, update_opts, true)
    end
    
    # MongoDB equivalent: { $pullAll : { field : value_array } }<br/>
    # Removes all occurrences of each value in value_array from field, if field is an array. If field is 
    # present but is not an array, an error condition is raised.
    #  user.pull_all("interests", ["watching paint dry", "sitting on my ass"])
    def pull_all(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$pullAll" => { mongo_field => create_array(val) } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        create_array(val).each do |v|
          hash[field].delete(v)
        end; true
      end
    end
    
    def pull_all!(field, val, update_opts={})
      pull_all(field, val, update_opts, true)
    end
    
    # MongoDB equivalent: { $inc : { field : value } }<br/>
    # Increments field by the number value if field is present in the object, otherwise sets field to the number value.
    #  user.inc("cents_in_wallet", 1000)
    def inc(field, val, update_opts={}, safe=false)
      send(get_modifier_meth(:inc), field, val, update_opts, safe)
    end
    
    def inc!(field, val, update_opts={})
      inc(field, val, update_opts, true)
    end
    
    # MongoDB equivalent: { $set : { field : value } }<br/>
    # Sets field to value. All datatypes are supported with $set.
    #  user.set("name", "Ben")
    def set(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      #field, hash = hash_for_field(field.to_s)
      
      op  = { "$set" => { mongo_field => val } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        set_value_for_key(field.to_s, val)
        #hash[field] = val
        true
      end
    end
    
    def set!(field, val, update_opts={})
      set(field, val, update_opts, true)
    end

    # MongoDB equivalent: { $unset : { field : 1} }<br/>
    # Deletes a given field. v1.3+
    #  user.unset("name")
    def unset(field, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      op = { "$unset" => { mongo_field => 1 } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash.delete(field)
        true
      end
    end
    
    def unset!(field, update_opts={})
      unset(field, update_opts, true)
    end
    
    # MongoDB equivalent: { $addToSet : { field : value } }<br/>
    # Adds value to the array only if its not in the array already.<br/>
    # Or to add many values:<br/>
    # { $addToSet : { a : { $each : [ 3 , 5 , 6 ] } } }
    #  user.add_to_set("friend_ids", BSON::ObjectId('...'))
    def add_to_set(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)

      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      return false if val.nil?
      
      if val.is_a?(Array)
        op  = { "$addToSet" => { mongo_field => { "$each" => val } } }
      else
        op  = { "$addToSet" => { mongo_field => val } }
      end
      
      res = true
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        create_array(val).each do |v|
          hash[field] << v unless hash[field].include?(v)
        end
        true
      end
    end
    
    def add_to_set!(field, val, update_opts={})
      add_to_set(field, val, update_opts, true)
    end
    
    # MongoDB equivalent: { $pop : { field : 1  } }<br/>
    # Removes the last element in an array (ADDED in 1.1)
    #  user.pop_last("friend_ids")
    def pop_last(field, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op = { "$pop" => { mongo_field => 1 } }
      
      res = true
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        hash[field].pop
        true
      end
    end
    
    def pop_last!(field, update_opts={})
      pop_last(field, update_opts, true)
    end
    
    # MongoDB equivalent: { $pop : { field : -1  } }<br/>
    # Removes the first element in an array (ADDED in 1.1)
    #  user.pop_first("friend_ids")
    def pop_first(field, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op = { "$pop" => { mongo_field => -1 } }
      
      res = true
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        hash[field].shift
        true
      end
    end
    
    def pop_first!(field, update_opts={})
      pop_first(field, update_opts, true)
    end
    
    private
    
    def prepare_modifier_flush(buffer)
      prepared_buffer = {}
      update_opts = {}
      buffer.each do |op, fields|
        prepared_buffer[op] ||= {}
        fields.each do |field, data|
          prepared_buffer[op][field] = data[:val]
          update_opts.merge!(data[:update_opts])
        end
      end
      [prepared_buffer, update_opts]
    end
    
    def chain_modifier(mod, field, val, update_opts={}, safe=false)
      @modifier_buffer[mod] ||= {}
      @modifier_buffer[mod][field] = {:val => val, 
                                     :update_opts => update_opts, 
                                     :safe => safe}
    end
    
    def get_modifier_meth(mod)
      @modifier_state == :chain ? "chain_#{mod}".to_sym : "simple_#{mod}".to_sym
    end
    
    def chain_push(field, val, update_opts={}, safe=false)
      chain_modifier("$push", field, val, update_opts, safe)
      self
    end
     
    def simple_push(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)

      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$push" => { mongo_field => val } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        hash[field] << val
        true
      end
    end
    
    def chain_push_all(field, val, update_opts={}, safe=false)
      chain_modifier("$pushAll", field, val, update_opts, safe)
      self
    end
    
    def simple_push_all(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      val = create_array(val)
      op  = { "$pushAll" => { mongo_field => val } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        val.each { |v| hash[field] << v }
        true
      end
    end
    
    def chain_pull(field, val, update_opts={}, safe=false)
      chain_modifier("$pull", field, val, update_opts, safe)
      self
    end
    
    def simple_pull(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      unless hash[field].nil? || hash[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$pull" => { mongo_field => val } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= []
        hash[field].delete(val)
        true
      end
    end
    
    def chain_inc(field, val, update_opts={}, safe=false)
      chain_modifier("$inc", field, val, update_opts, safe)
      self
    end
    
    def simple_inc(field, val, update_opts={}, safe=false)
      mongo_field = field.to_s
      field, hash = hash_for_field(mongo_field)
      
      unless hash[field].nil? || ["Fixnum","Float"].include?(hash[field].class.to_s)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$inc" => { mongo_field => val } }
      res = true
      
      safe == true ? res = update!(update_opts, op) : update(update_opts, op)
      
      if res
        hash[field] ||= 0
        hash[field] += val
        true
      end
    end
  end
end