require 'helper'

class TestMongomatic < Test::Unit::TestCase
  should "be able to insert, update, remove documents" do
    Person.collection.remove
    
    p = Person.new
    
    assert !p.valid?
    assert_equal(["Name can't be empty"], p.errors.full_messages)
    
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
  
  should "be able to limit and sort" do
    Person.collection.remove
    p = Person.new(:name => "Ben", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert.is_a?(BSON::ObjectID)
    assert_equal 1, Person.collection.count
    p2 = Person.new(:name => "Ben2", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p2.insert.is_a?(BSON::ObjectID)
    assert_equal 2, Person.collection.count
    
    cursor = Person.find({"_id" => p["_id"]})
    found  = cursor.next
    assert_equal p, found
    
    cursor = Person.find()
    assert_equal 0, cursor.current_limit
    assert_equal 2, cursor.to_a.size
    cursor = Person.find().limit(1)
    assert_equal 1, cursor.current_limit
    assert_equal 1, cursor.to_a.size
    cursor = Person.find().limit(1)
    assert_equal p, cursor.next
    assert_equal nil, cursor.next
    cursor = Person.find().limit(1).skip(1)
    assert_equal p2, cursor.next
  end
end
