module Mongomatic
  # Provides convenience methods for atomic MongoDB operations.
  module Modifiers

    # MongoDB equivalent: { $push : { field : value } }<br/>
    # Appends value to field, if field is an existing array, otherwise sets field to the array [value] 
    # if field is not present. If field is present but is not an array, an error condition is raised.
    #  user.push("interests", "skydiving")
    def push(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$push" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $pushAll : { field : value_array } }<br/>
    # Appends each value in value_array to field, if field is an existing array, otherwise sets field to 
    # the array value_array if field is not present. If field is present but is not an array, an error 
    # condition is raised.
    #  user.push("interests", ["skydiving", "coding"])
    def push_all(field, val, do_reload=true)
      field = field.to_s
      val = Array(val)
      if update({}, { "$pushAll" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $pull : { field : _value } }<br/>
    # Removes all occurrences of value from field, if field is an array. If field is present but is not 
    # an array, an error condition is raised.
    #  user.pull("interests", "watching paint dry")
    def pull(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$pull" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $pullAll : { field : value_array } }<br/>
    # Removes all occurrences of each value in value_array from field, if field is an array. If field is 
    # present but is not an array, an error condition is raised.
    #  user.pull_all("interests", ["watching paint dry", "sitting on my ass"])
    def pull_all(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$pullAll" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $inc : { field : value } }<br/>
    # Increments field by the number value if field is present in the object, otherwise sets field to the number value.
    #  user.inc("cents_in_wallet", 1000)
    def inc(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$inc" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $set : { field : value } }<br/>
    # Sets field to value. All datatypes are supported with $set.
    #  user.set("name", "Ben")
    def set(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$set" => { field => val } })
        reload if do_reload; true
      end
    end

    # MongoDB equivalent: { $unset : { field : 1} }<br/>
    # Deletes a given field. v1.3+
    #  user.unset("name")
    def unset(field, do_reload=true)
      field = field.to_s
      if update({}, { "$unset" => { field => 1 } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $addToSet : { field : value } }<br/>
    # Adds value to the array only if its not in the array already.<br/>
    # Or to add many values:<br/>
    # { $addToSet : { a : { $each : [ 3 , 5 , 6 ] } } }
    #  user.add_to_set("friend_ids", BSON::ObjectID('...'))
    def add_to_set(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$addToSet" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $pop : { field : 1  } }<br/>
    # Removes the last element in an array (ADDED in 1.1)
    #  user.pop_last("friend_ids")
    def pop_last(field, do_reload=true)
      field = field.to_s
      if update({}, { "$pop" => { field => 1 } })
        reload if do_reload; true
      end
    end
    
    # MongoDB equivalent: { $pop : { field : -1  } }<br/>
    # Removes the first element in an array (ADDED in 1.1)
    #  user.pop_first("friend_ids")
    def pop_first(field, do_reload=true)
      field = field.to_s
      if update({}, { "$pop" => { field => -1 } })
        reload if do_reload; true
      end
    end
    
  end
end