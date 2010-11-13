require 'helper'
require 'minitest/autorun'

class TestValidations < MiniTest::Unit::TestCase
  def test_array_style_errors
    f = Foobar.new
    assert !f.valid?
    assert_equal ["color must not be blank", "missing style"], f.errors.full_messages
    f["color"] = "pink"; f.valid?
    assert_equal ["missing style"], f.errors.full_messages
    f["style"] = "awesome"; f.valid?
    assert_equal [], f.errors.full_messages
  end
 
  def test_be_expect
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
  
  def test_be_expected_with_block
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
  
  def test_be_expected_with_method_call
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
   
  def test_be_present
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
  
  def test_be_a_number
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
  
  def test_be_match
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
  
  def test_be_of_length
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
  
  def test_be_reference
    id = Person.new('name' => 'jordan').insert
    p = Person.new
    class << p
      def validate
        expectations do 
          be_reference self['friend'], 'friend must be an ObjectId'
        end
      end
    end
    
    assert !p.valid?
    assert_equal ["friend must be an ObjectId"], p.errors.full_messages
    
    p['friend'] = id
    
    assert p.valid?
  end
  
  def test_expectations_must_be_in_helper_block
    p = Person.new
    class << p
      def validate
        be_present self['name'], ''
      end
    end
    
    assert_raises NoMethodError do
      p.valid?
    end
    
    class << p
      def validate
        expectations {  }
        be_present
      end
    end
    
    assert_raises NameError do 
      p.valid?
    end
  end
  
  def test_errors_on_two_part_error_messages
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
    assert_equal ['cannot be empty', 'must be at least 3 characters long'], p.errors.on(:name)
    assert_equal ['must be a number'], p.errors.on('age')
    
    p['name'] = 'Jo'
    p['age'] = 21
    
    p.valid?
    assert_equal ['must be at least 3 characters long'], p.errors.on('name')
    assert_equal [], p.errors.on(:age)
    
    p['name'] = 'Jordan'
    
    p.valid?
    assert_equal [], p.errors.on(:name)
  end

  def test_errors_on_one_part_error_message
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['name'], ['name', 'cannot be empty' ]
          be_of_length self['name'], ['name', 'must be at least 3 characters long'], :minimum => 3
          be_a_number self['age'],  ['age','must be a number']
        end
      end
    end

    p.valid?
    assert_equal ['cannot be empty', 'must be at least 3 characters long'], p.errors.on(:name)
    assert_equal ['must be a number'], p.errors.on('age')
    
    p['name'] = 'Jo'
    p['age'] = 21
    
    p.valid?
    assert_equal ['must be at least 3 characters long'], p.errors.on('name')
    assert_equal [], p.errors.on(:age)
    
    p['name'] = 'Jordan'
    
    p.valid?
    assert_equal [], p.errors.on(:name)
  end
  
  def test_errors_on_case_insensitive
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['name'], ['name', 'cannot be empty']
          be_expected self['age'], ['age','cannot be empty']
        end
      end
    end
    
    p.valid?
    assert_equal ['cannot be empty'], p.errors.on('name')
    assert_equal ['cannot be empty'], p.errors.on(:age)
  end

  def test_errors_on_multi_word_fields
    p = Person.new
    class << p
      def validate
        expectations do 
          be_expected self['hair_color'], ['hair_color', 'must exist']
        end
      end
    end
    
    p.valid?
    assert_equal ['must exist'], p.errors.on(:hair_color)
  end
end