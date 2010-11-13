require 'helper'
require 'minitest/autorun'

class TestMisc < MiniTest::Unit::TestCase
  def test_keys_can_be_strings_or_symbols
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1[:address] = { :city => "San Francisco" }
    assert_equal "Jordan", p1["name"]
    assert_equal "Jordan", p1[:name]
    assert_equal "San Francisco", p1["address"]["city"]
    assert_equal "San Francisco", p1[:address][:city]
    p1.insert
    
    p1 = Person.find_one(:name => "Jordan")
    assert_equal "Jordan", p1["name"]
    assert_equal "Jordan", p1[:name]
    assert_equal "San Francisco", p1["address"]["city"]
    assert_equal "San Francisco", p1[:address][:city]
  end
  
  def test_empty_cursor
    Person.collection.drop
    assert Person.empty?
    assert Person.find.empty?
    p1 = Person.new(:name => "Jordan")
    p1.insert
    assert !Person.empty?
    assert !Person.find.empty?
    assert !Person.find({"name" => "Jordan"}).empty?
    assert Person.find({"name" => "Ben"}).empty?
    p1.remove!
    assert Person.empty?
    assert Person.find.empty?
    assert Person.find({"name" => "Jordan"}).empty?
  end
  
  def test_enumerable
    Person.collection.drop
    p1 = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    p2 = Person.new(:name => "Ben2", :birth_year => 1986, :created_at => Time.now.utc, :admin => true)
    assert p1.insert.is_a?(BSON::ObjectId)
    assert p2.insert.is_a?(BSON::ObjectId)
    assert_equal 2, Person.collection.count
    assert_equal 2, Person.find.inject(0) { |sum, p| assert p.is_a?(Person); sum += 1 }
    assert_equal p2, Person.find.max { |p1,p2| p1["birth_year"] <=> p2["birth_year"] }
  end
  
  def test_enumerable_cursor
    Person.collection.drop
    1000.upto(2000) do |i|
      p = Person.new(:name => "Ben#{i}", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
      assert p.insert.is_a?(BSON::ObjectId)
    end
    i = 1000
    Person.find().sort(["name", :asc]).each { |p| assert_equal "Ben#{i}", p["name"]; i += 1 }
    Person.find().sort(["name", :asc]).each_with_index { |p,i| assert_equal "Ben#{1000+i}", p["name"] }
    
    p = Person.find().limit(1).next
    assert Person.find().sort(["name", :asc]).include?(p)
    
    assert_equal 10, Person.find().limit(10).to_a.size
  end
  
  def test_merging_hashes
    Person.collection.drop
    p = Person.new(:name => "Ben", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert.is_a?(BSON::ObjectId)
    assert_equal 1, Person.collection.count
    p.merge(:birth_year => 1986)
    p.update
    p = Person.find({"_id" => p["_id"]}).next
    assert_equal 1986, p["birth_year"]
  end
  
  def test_callbacks
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    p.callback_tests = []
    assert p.callback_tests.empty?
    assert p.valid?
    assert_equal [:before_validate, :after_validate], p.callback_tests
    p.callback_tests = []
    assert p.insert.is_a?(BSON::ObjectId)
    assert_equal [:before_validate, :after_validate,  :before_insert, :before_insert_or_update, :after_insert, :after_insert_or_update], p.callback_tests
    p.callback_tests = []
    p.update
    assert_equal [:before_validate, :after_validate, :before_update, :before_insert_or_update, :after_update, :after_insert_or_update], p.callback_tests
    p.callback_tests = []
    p.remove
    assert_equal [:before_remove, :after_remove], p.callback_tests
    Person.class_callbacks = []
    Person.drop
    assert_equal [:before_drop, :after_drop], Person.class_callbacks
  end
  
  def test_unique_index
    Person.collection.drop
    Person.create_indexes
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert!.is_a?(BSON::ObjectId)
    assert_equal 1, Person.count
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert_raises(Mongo::OperationFailure) { p.insert! }
    
    assert_equal 1, Person.count
  end
  
  def test_is_new_flag
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
  
  def test_custom_id
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
  
  def test_be_able_to_drop_collection
    p = Person.new
    p['name'] = "Jordan"
    p.insert

    assert !Person.empty?

    Person.drop
    assert Person.empty?
  end
  
  def test_has_key_with_symbols_and_strings
    p = Person.new
    
    assert !p.has_key?(:name)
    
    p['name'] = 'Jordan'
    
    assert p.has_key?(:name)
    assert p.has_key?('name')
  end
  
  def test_has_key
    p = Person.new(:employer => {:name => 'Meta+Level Games', 
                                 :function => 'Makes things with code', 
                                 :something_else => {
                                   :with_a_key => 'And Value'}
                                 })
                                 
    assert !p.has_key?('employer.started_at')
    assert p.has_key?('employer.name')
    assert !p.has_key?('non.existent')
    assert !p.has_key?('employer.something_else.not_here')
    assert p.has_key?('employer.something_else.with_a_key')
  end
  
  def test_value_for_key
    p = Person.new(:employer => {:name => 'Meta+Level Games', 
                                 :function => 'Makes things with code', 
                                 :something_else => {
                                   :with_a_key => 'And Value'}
                                 })
    assert_equal "And Value", p.value_for_key("employer.something_else.with_a_key")
    assert_equal "Meta+Level Games", p.value_for_key("employer.name")
    assert_nil p.value_for_key("some_key.that_does_not.exist")
  end
  
  def test_no_method_error_in_callback
    assert_raises(NoMethodError) { Thing.new.insert }
    assert_raises(NoMethodError) { Thing.drop }
  end
end
