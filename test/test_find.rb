require 'helper'
require 'minitest/autorun'

class TestFind < MiniTest::Unit::TestCase
  def test_find_one_with_query
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal p1, Person.find_one(:name => "Jordan")
  end
  
  def test_find_one_with_id
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal p1, Person.find_one(p1['_id'])
  end
  
  def test_find_one_with_id_or_hash
    Person.collection.drop
    Person.create_indexes
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert!.is_a?(BSON::ObjectId)
    assert_equal 1, Person.count
    
    found = Person.find({"_id" => BSON::ObjectId(p["_id"].to_s)}).next
    assert_equal found, p
    
    assert_raises(TypeError) { Person.find_one(p["_id"].to_s) }
    
    found = Person.find_one({"_id" => p["_id"].to_s})
    assert_equal found, nil
    
    found = Person.find_one({"_id" => BSON::ObjectId(p["_id"].to_s)})
    assert_equal found, p
  end
  
  def test_limit_and_sort
    Person.collection.drop
    p = Person.new(:name => "Ben", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert.is_a?(BSON::ObjectId)
    assert_equal 1, Person.collection.count
    p2 = Person.new(:name => "Ben2", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p2.insert.is_a?(BSON::ObjectId)
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
  
  def test_instance_of_class_returned_on_find_one
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal Person, Person.find_one(:name => "Jordan").class
  end
  
end