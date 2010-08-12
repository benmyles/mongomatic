require 'helper'

class TestMongomatic < Test::Unit::TestCase
  should "find one with a query" do
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal p1, Person.find_one(:name => "Jordan")
  end
  
  should "find one with an instance of BSON::ObjectID" do
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal p1, Person.find_one(p1['_id'])
  end
  
  should "find one with ObjectID or hash only" do
    Person.collection.drop
    Person.create_indexes
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert_safe.is_a?(BSON::ObjectID)
    assert_equal 1, Person.count
    
    found = Person.find({"_id" => BSON::ObjectID(p["_id"].to_s)}).next
    assert_equal found, p
    
    assert_raise(TypeError) { Person.find_one(p["_id"].to_s) }
    
    found = Person.find_one({"_id" => p["_id"].to_s})
    assert_equal found, nil
    
    found = Person.find_one({"_id" => BSON::ObjectID(p["_id"].to_s)})
    assert_equal found, p
  end
  
  should "return an instance of class when finding one" do
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal Person, Person.find_one(:name => "Jordan").class
  end
  should "work with enumerable methods" do
    Person.collection.drop
    p1 = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    p2 = Person.new(:name => "Ben2", :birth_year => 1986, :created_at => Time.now.utc, :admin => true)
    assert p1.insert.is_a?(BSON::ObjectID)
    assert p2.insert.is_a?(BSON::ObjectID)
    assert_equal 2, Person.collection.count
    assert_equal 2, Person.find.inject(0) { |sum, p| assert p.is_a?(Person); sum += 1 }
    assert_equal p2, Person.find.max { |p1,p2| p1["birth_year"] <=> p2["birth_year"] }
  end
  
  should "be able to insert, update, remove documents" do
    Person.collection.drop
    
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
    Person.collection.drop
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
    Person.collection.drop
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
    Person.collection.drop
    p = Person.new(:name => "Ben", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert.is_a?(BSON::ObjectID)
    assert_equal 1, Person.collection.count
    p.merge(:birth_year => 1986)
    p.update
    p = Person.find({"_id" => p["_id"]}).next
    assert_equal 1986, p["birth_year"]
  end
  
  should "have callbacks" do    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    p.callback_tests = []
    assert p.callback_tests.empty?
    assert p.valid?
    assert_equal [:before_validate, :after_validate], p.callback_tests
    p.callback_tests = []
    assert p.insert.is_a?(BSON::ObjectID)
    assert_equal [:before_validate, :after_validate,  :before_insert, :before_insert_or_update, :after_insert, :after_insert_or_update], p.callback_tests
    p.callback_tests = []
    p.update
    assert_equal [:before_validate, :after_validate, :before_update, :before_insert_or_update, :after_update, :after_insert_or_update], p.callback_tests
    p.callback_tests = []
    p.remove
    assert_equal [:before_remove, :after_remove], p.callback_tests
  end
  
  should "raise an error on unique index dup insert" do
    Person.collection.drop
    Person.create_indexes
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert_safe.is_a?(BSON::ObjectID)
    assert_equal 1, Person.count
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert_raise(Mongo::OperationFailure) { p.insert_safe }
    
    assert_equal 1, Person.count
  end
  
  should "have the is_new flag set appropriately" do
    Person.collection.drop
    p = Person.new
    assert p.is_new?
    assert !p.insert
    assert p.is_new?
    p["name"] = "Ben"
    assert p.insert
    assert !p.is_new?
    p = Person.find_one(p["_id"])
    assert !p.is_new?
  end
  
  should "be able to set a custom id" do
    Person.collection.drop
    p = Person.new(:name => "Ben")
    assert p.is_new?
    p["_id"] = "mycustomid"
    assert p.insert
    found = Person.find_one({"_id" => "mycustomid"})
    assert_equal found, p
    assert !p.is_new?
    found["age"] = 26
    assert found.update
    found = Person.find_one({"_id" => "mycustomid"})
    assert_equal found["_id"], "mycustomid"
    assert_equal 26, found["age"]
  end
end
