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

    cursor = Person.find().sort("name", Mongo::ASCENDING)
    assert_equal p, cursor.next

    cursor = Person.find().sort("name", Mongo::DESCENDING)
    assert_equal p2, cursor.next
  end
  
  should "cursor implements enumerable" do
    Person.collection.remove
    1000.upto(2000) do |i|
      p = Person.new(:name => "Ben#{i}", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
      assert p.insert.is_a?(BSON::ObjectID)
    end
    i = 1000
    Person.find().sort(["name", :asc]).each { |p| assert_equal "Ben#{i}", p["name"]; i += 1 }
    Person.find().sort(["name", :asc]).each_with_index { |p,i| assert_equal "Ben#{1000+i}", p["name"] }
    
    p = Person.find().limit(1).next
    assert Person.find().sort(["name", :asc]).include?(p)
    
    assert_equal 10, Person.find().limit(10).to_a.size
  end
  
  should "be able to merge hashes" do
    Person.collection.remove
    p = Person.new(:name => "Ben", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert.is_a?(BSON::ObjectID)
    assert_equal 1, Person.collection.count
    p.merge(:birth_year => 1986)
    p.update
    p = Person.find({"_id" => p["_id"]}).next
    assert_equal 1986, p["birth_year"]
  end
end
