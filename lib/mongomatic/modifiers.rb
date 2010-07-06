module Mongomatic
  module Modifiers

    # { $push : { field : value } }
    # appends value to field, if field is an existing array, otherwise sets field to the array [value] 
    # if field is not present. If field is present but is not an array, an error condition is raised.
    def push(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$push" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # { $pushAll : { field : value_array } }
    # appends each value in value_array to field, if field is an existing array, otherwise sets field to 
    # the array value_array if field is not present. If field is present but is not an array, an error 
    # condition is raised.
    def push_all(field, val, do_reload=true)
      field = field.to_s
      val = Array(val)
      if update({}, { "$pushAll" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # { $pull : { field : _value } }
    # removes all occurrences of value from field, if field is an array. If field is present but is not 
    # an array, an error condition is raised.
    def pull(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$pull" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # { $pullAll : { field : value_array } }
    # removes all occurrences of each value in value_array from field, if field is an array. If field is 
    # present but is not an array, an error condition is raised.
    def pullAll(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$pullAll" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # { $inc : { field : value } }
    # increments field by the number value if field is present in the object, otherwise sets field to the number value.
    def inc(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$inc" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # { $set : { field : value } }
    # sets field to value. All datatypes are supported with $set.
    def set(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$set" => { field => val } })
        reload if do_reload; true
      end
    end

    # { $unset : { field : 1} }
    # Deletes a given field. v1.3+
    def unset(field, do_reload=true)
      field = field.to_s
      if update({}, { "$unset" => { field => 1 } })
        reload if do_reload; true
      end
    end
    
    # { $addToSet : { field : value } }
    # Adds value to the array only if its not in the array already.
    # 
    # To add many valuest.update
    # 
    # { $addToSet : { a : { $each : [ 3 , 5 , 6 ] } } }
    def add_to_set(field, val, do_reload=true)
      field = field.to_s
      if update({}, { "$addToSet" => { field => val } })
        reload if do_reload; true
      end
    end
    
    # { $pop : { field : 1  } }
    # removes the last element in an array (ADDED in 1.1)
    def pop_last(field, do_reload=true)
      field = field.to_s
      if update({}, { "$pop" => { field => 1 } })
        reload if do_reload; true
      end
    end
    
    # { $pop : { field : -1  } }
    # removes the first element in an array (ADDED in 1.1)
    def pop_first(field, do_reload=true)
      field = field.to_s
      if update({}, { "$pop" => { field => -1 } })
        reload if do_reload; true
      end
    end
    
  end
end