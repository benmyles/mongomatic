require 'helper'

class TestMongomatic < Test::Unit::TestCase
  should "be able to insert, update, remove documents" do
    Person.collection.remove
    
    p = Person.new
    
    assert !p.valid?
    assert_equal({:name=>["can't be blank"]}, p.errors)
    
    p["name"] = "Ben Myles"
    p["birth_year"] = 1984
    p["created_at"] = Time.now.utc
    p["admin"] = true
    
    assert !p.update
    
    assert p.insert.is_a?(BSON::ObjectID)
    
    assert_equal 1, Person.collection.count

    cursor = Person.find({"_id" => p["_id"]})
    found  = cursor.next
    assert_equal p, found
    assert_equal "Ben Myles", found["name"]
    
    p["name"] = "Benjamin"
    assert p.update
    
    cursor = Person.find({"_id" => p["_id"]})
    found  = cursor.next
    assert_equal p, found
    assert_equal "Benjamin", found["name"]
    
    assert p.remove
    assert p.removed?
    cursor = Person.find({"_id" => p["_id"]})
    found  = cursor.next
    assert_nil found
  end
end
