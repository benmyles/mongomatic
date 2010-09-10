require 'helper'

class TestMongomatic < Test::Unit::TestCase
  should "find one with a query" do
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal p1, Person.find_one(:name => "Jordan")
  end
  
  should "find one with an instance of BSON::ObjectId" do
    Person.collection.drop
    p1 = Person.new(:name => "Jordan")
    p1.insert
    
    assert_equal p1, Person.find_one(p1['_id'])
  end
  
  should "accurately return whether the cursor is or is not empty" do
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
  
  should "find one with ObjectId or hash only" do
    Person.collection.drop
    Person.create_indexes
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert!.is_a?(BSON::ObjectId)
    assert_equal 1, Person.count
    
    found = Person.find({"_id" => BSON::ObjectId(p["_id"].to_s)}).next
    assert_equal found, p
    
    assert_raise(TypeError) { Person.find_one(p["_id"].to_s) }
    
    found = Person.find_one({"_id" => p["_id"].to_s})
    assert_equal found, nil
    
    found = Person.find_one({"_id" => BSON::ObjectId(p["_id"].to_s)})
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
    assert p1.insert.is_a?(BSON::ObjectId)
    assert p2.insert.is_a?(BSON::ObjectId)
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
    
    assert p.insert.is_a?(BSON::ObjectId)
    
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
  
  should "cursor implements enumerable" do
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
  
  should "be able to merge hashes" do
    Person.collection.drop
    p = Person.new(:name => "Ben", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert.is_a?(BSON::ObjectId)
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
  
  should "raise an error on unique index dup insert" do
    Person.collection.drop
    Person.create_indexes
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert p.insert!.is_a?(BSON::ObjectId)
    assert_equal 1, Person.count
    
    p = Person.new(:name => "Ben1", :birth_year => 1984, :created_at => Time.now.utc, :admin => true)
    assert_raise(Mongo::OperationFailure) { p.insert! }
    
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
 
  should "be able to use the be_expect expectation" do
    p = Person.new
    class << p
      def validate
        expectations do
          be_expected self['alive'], "Alive must be true"
          not_be_expected self['dead'], "Dead must be false"
        end
      end
    end
    
    assert !p.valid?
    assert_equal ['Alive must be true'], p.errors.full_messages
    
    p['alive'] = true
    assert p.valid?
    
    p['dead'] = true
    assert !p.valid?
    assert_equal ['Dead must be false'], p.errors.full_messages
  end
  
  should "be able to use be_expected with a block" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected lambda { self['name'].is_a? String }, "Name must be a string"
          not_be_expected lambda { self['alive'] && self['dead'] }, "Cannot be alive and dead"
        end
      end
    end
    
    p['name'] = 1
    assert !p.valid?
    assert_equal p.errors.full_messages, ["Name must be a string"]
    
    p['alive'] = true
    p['dead'] = true
    p['name'] = "Jordan"
    
    assert !p.valid?
    assert_equal p.errors.full_messages, ["Cannot be alive and dead"]
    
    p['dead'] = false
    assert p.valid?
  end
  
  should "be able to use be_expected with a method call" do
    p = Person.new
    class << p
      def validate
        expectations do
          be_expected :method_1, "Method 1 must return true"
          not_be_expected :method_2, "Method 2 must return false"
        end
      end
      
      def method_1
        (self['name'] == 'Jordan') ? true : false
      end
      
      def method_2 
        (self['age'] == 21) ? false : true 
      end
    end
    
    assert !p.valid?
    assert_equal ["Method 1 must return true", "Method 2 must return false"], p.errors.full_messages
    
    p['name'] = 'Jordan'
    p['age'] = 21
    
    assert p.valid?
  end
   
  should "be able to use the be_present expectation" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_present self['name'], 'name cannot be blank' 
          not_be_present self['age'],  'age must be blank'
        end
      end
    end
    
    assert !p.valid?
    assert_equal ['name cannot be blank'], p.errors.full_messages
    
    p['name'] = "Jordan"
    p['age'] = 21
    
    
    assert !p.valid?
    assert_equal ['age must be blank'], p.errors.full_messages
    
    p['age'] = nil
    
    assert p.valid?
    
  end
  
  should "be able to use be_a_number expectation" do
    p = Person.new
    class << p
      def validate
        expectations do
          be_a_number self['age'], 'Age is not a number'
          not_be_a_number self['name'], 'Name cannot be a number'
          be_a_number self['birth_year'], 'Birth year is not a number', :allow_nil => true
        end
      end
    end
    
    assert !p.valid?
    assert_equal ["Age is not a number"], p.errors.full_messages
    
    p['age'] = 21
    p['name'] = 65
    
    assert !p.valid?
    assert_equal ["Name cannot be a number"], p.errors.full_messages
    
    p['name'] = 'Jordan'
    
    assert p.valid?
  end
  
  should "be able to use be_match expectation" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_match self['name'], "Name must start with uppercase letter", :with => /[A-Z][a-z]*/
          not_be_match self['nickname'], "Nickname cannot start with uppercase letter", :with => /[A-Z][a-z]*/
          be_match self['age'], "Age must only contain digits", :with => /\d+/, :allow_nil => true
        end
      end
    end
    
    assert !p.valid?
    assert_equal ["Name must start with uppercase letter"], p.errors.full_messages
    
    p['name'] = 'Jordan'
    p['nickname'] = 'Jordan'
    
    assert !p.valid?
    assert_equal ["Nickname cannot start with uppercase letter"], p.errors.full_messages
    
    p['nickname'] = 'jordan'
    
    assert p.valid?
    
    p['age'] = 'asd'
    
    assert !p.valid?
    assert_equal ["Age must only contain digits"], p.errors.full_messages
    
    p['age'] = '21'
    
    assert p.valid?
    
  end
  
  should "be able to use be_of_length expectation" do
    p = Person.new
    class << p
      def validate
        expectations do
          be_of_length self['name'], "Name must be 3 characters long", :minimum => 3
          be_of_length self['nickname'], "Nickname must not be longer than 5 characters", :maximum => 5
          be_of_length self['computers'], "Can only specify between 1 and 3 computers", :range => 1..3
          be_of_length self['status'], "Status must be a minimum of 1 character", :minumum => 1, :allow_nil => true
        end
      end
    end
    
    assert !p.valid?
    assert_equal ["Name must be 3 characters long",  
                  "Can only specify between 1 and 3 computers"], p.errors.full_messages
            
    p['name'] = 'Jordan'
    p['nickname'] = 'Jordan'
    
    assert !p.valid?
    assert_equal ["Nickname must not be longer than 5 characters", 
                  "Can only specify between 1 and 3 computers"], p.errors.full_messages
                  
    p['nickname'] = 'abc'
    p['computers'] = ['comp_a']
    
    assert p.valid?
  end
  
  should "raise an error if expectations are called outside of helper block" do
    p = Person.new
    class << p
      def validate
        be_present self['name'], ''
      end
    end
    
    assert_raise NoMethodError do
      p.valid?
    end
    
    class << p
      def validate
        expectations {  }
        be_present
      end
    end
    
    assert_raise NameError do 
      p.valid?
    end
  end
  
  should "be able to drop a collection" do
    p = Person.new
    p['name'] = "Jordan"
    p.insert

    assert !Person.empty?

    Person.drop
    assert Person.empty?
  end
  
  should "be able to use errors.on with two part error messages" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['name'], ['name', 'cannot be empty']
          be_of_length self['name'], ['name', 'must be at least 3 characters long'], :minimum => 3
          be_a_number self['age'], ['age', 'must be a number']
        end
      end
    end

    p.valid?
    assert_equal ['name cannot be empty', 'name must be at least 3 characters long'], p.errors.on(:name)
    assert_equal 'age must be a number', p.errors.on('age')
    
    p['name'] = 'Jo'
    p['age'] = 21
    
    p.valid?
    assert_equal 'name must be at least 3 characters long', p.errors.on('name')
    assert_nil p.errors.on(:age)
    
    p['name'] = 'Jordan'
    
    p.valid?
    assert_nil p.errors.on(:name)
  end

  should "be able to use errors.on with one part error messages" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['name'], 'name cannot be empty' 
          be_of_length self['name'], 'name must be at least 3 characters long', :minimum => 3
          be_a_number self['age'],  'age must be a number'
        end
      end
    end

    p.valid?
    assert_equal ['name cannot be empty', 'name must be at least 3 characters long'], p.errors.on(:name)
    assert_equal 'age must be a number', p.errors.on('age')
    
    p['name'] = 'Jo'
    p['age'] = 21
    
    p.valid?
    assert_equal 'name must be at least 3 characters long', p.errors.on('name')
    assert_nil p.errors.on(:age)
    
    p['name'] = 'Jordan'
    
    p.valid?
    assert_nil p.errors.on(:name)
  end
  
  should "be able to use errors.on case insensitive" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['name'], ['Name', 'cannot be empty']
          be_expected self['age'], 'Age cannot be empty'
        end
      end
    end
    
    p.valid?
    assert_equal 'Name cannot be empty', p.errors.on('name')
    assert_equal 'Age cannot be empty', p.errors.on(:age)
  end

  should "be able to use errors.on with multi word fields" do
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['hair_color'], 'Hair color must exist'
        end
      end
    end
    
    p.valid?
    assert_equal 'Hair color must exist', p.errors.on(:hair_color)
  end
  
  should "be able to use has_key?" do
    p = Person.new
    
    assert !p.has_key?(:name)
    
    p['name'] = 'Jordan'
    
    assert p.has_key?(:name)
    assert p.has_key?('name')
  end
  
  should "be able to reach into keys with has_key?" do
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
end
