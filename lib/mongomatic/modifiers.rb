module Mongomatic
  # Provides convenience methods for atomic MongoDB operations.
  module Modifiers

    class UnexpectedFieldType < RuntimeError; end
    
    # MongoDB equivalent: { $push : { field : value } }<br/>
    # Appends value to field, if field is an existing array, otherwise sets field to the array [value] 
    # if field is not present. If field is present but is not an array, error is returned.
    def push(field, val, safe=false)
      field = field.to_s

      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$push" => { field => val } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        self[field] << val
        true
      end
    end
    
    def push!(field, val)
      push(field, val, true)
    end
    
    # MongoDB equivalent: { $pushAll : { field : value_array } }<br/>
    # Appends each value in value_array to field, if field is an existing array, otherwise sets field to 
    # the array value_array if field is not present. If field is present but is not an array, an error 
    # condition is raised.
    #  user.push("interests", ["skydiving", "coding"])
    def push_all(field, val, safe=false)
      field = field.to_s
      
      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      val = Array(val)
      op  = { "$pushAll" => { field => val } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        val.each { |v| self[field] << v }
        true
      end
    end
    
    def push_all!(field, val)
      push_all(field, val, true)
    end
    
    # MongoDB equivalent: { $pull : { field : _value } }<br/>
    # Removes all occurrences of value from field, if field is an array. If field is present but is not 
    # an array, an error condition is raised.
    #  user.pull("interests", "watching paint dry")
    def pull(field, val, safe=false)
      field = field.to_s
      
      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$pull" => { field => val } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        self[field].delete(val)
        true
      end
    end
    
    def pull!(field, val)
      pull(field, val, true)
    end
    
    # MongoDB equivalent: { $pullAll : { field : value_array } }<br/>
    # Removes all occurrences of each value in value_array from field, if field is an array. If field is 
    # present but is not an array, an error condition is raised.
    #  user.pull_all("interests", ["watching paint dry", "sitting on my ass"])
    def pull_all(field, val, safe=false)
      field = field.to_s
      
      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$pullAll" => { field => Array(val) } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        Array(val).each do |v|
          self[field].delete(v)
        end; true
      end
    end
    
    def pull_all!(field, val)
      pull_all(field, val, true)
    end
    
    # MongoDB equivalent: { $inc : { field : value } }<br/>
    # Increments field by the number value if field is present in the object, otherwise sets field to the number value.
    #  user.inc("cents_in_wallet", 1000)
    def inc(field, val, safe=false)
      field = field.to_s
      
      unless self[field].nil? || ["Fixnum","Float"].include?(self[field].class.to_s)
        raise(UnexpectedFieldType)
      end
      
      op  = { "$inc" => { field => val } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= 0
        self[field] += val
        true
      end
    end
    
    def inc!(field, val)
      inc(field, val, true)
    end
    
    # MongoDB equivalent: { $set : { field : value } }<br/>
    # Sets field to value. All datatypes are supported with $set.
    #  user.set("name", "Ben")
    def set(field, val, safe=false)
      field = field.to_s
      
      op  = { "$set" => { field => val } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] = val
        true
      end
    end
    
    def set!(field, val)
      set(field, val, true)
    end

    # MongoDB equivalent: { $unset : { field : 1} }<br/>
    # Deletes a given field. v1.3+
    #  user.unset("name")
    def unset(field, safe=false)
      field = field.to_s
      
      op = { "$unset" => { field => 1 } }
      res = true
      
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        @doc.delete(field)
        true
      end
    end
    
    def unset!(field)
      unset(field, true)
    end
    
    # MongoDB equivalent: { $addToSet : { field : value } }<br/>
    # Adds value to the array only if its not in the array already.<br/>
    # Or to add many values:<br/>
    # { $addToSet : { a : { $each : [ 3 , 5 , 6 ] } } }
    #  user.add_to_set("friend_ids", BSON::ObjectID('...'))
    def add_to_set(field, val, safe=false)
      field = field.to_s
      
      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      return false if val.nil?
      
      if val.is_a?(Array)
        op  = { "$addToSet" => { field => { "$each" => val } } }
      else
        op  = { "$addToSet" => { field => val } }
      end
      
      res = true
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        Array(val).each do |v|
          self[field] << v unless self[field].include?(v)
        end
        true
      end
    end
    
    def add_to_set!(field, val)
      add_to_set(field, val, true)
    end
    
    # MongoDB equivalent: { $pop : { field : 1  } }<br/>
    # Removes the last element in an array (ADDED in 1.1)
    #  user.pop_last("friend_ids")
    def pop_last(field, safe=false)
      field = field.to_s
      
      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op = { "$pop" => { field => 1 } }
      
      res = true
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        self[field].pop
        true
      end
    end
    
    def pop_last!(field)
      pop_last(field, true)
    end
    
    # MongoDB equivalent: { $pop : { field : -1  } }<br/>
    # Removes the first element in an array (ADDED in 1.1)
    #  user.pop_first("friend_ids")
    def pop_first(field, safe=false)
      field = field.to_s
      
      unless self[field].nil? || self[field].is_a?(Array)
        raise(UnexpectedFieldType)
      end
      
      op = { "$pop" => { field => -1 } }
      
      res = true
      safe == true ? res = update!({}, op) : update({}, op)
      
      if res
        self[field] ||= []
        self[field].shift
        true
      end
    end
    
    def pop_first!(field)
      pop_first(field, true)
    end
    
  end
end