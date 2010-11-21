require 'helper'
require 'minitest/autorun'

class TestModifiers < MiniTest::Unit::TestCase
  def setup
    Person.collection.drop
  end
  
  def test_push
    p1 = Person.new(:name => "Jordan")
    p1.insert
    assert p1.push("interests", "skydiving")
    assert p1["interests"].include?("skydiving")
    p1 = Person.find_one(p1["_id"])
    assert p1["interests"].include?("skydiving")
    assert p1.push!("interests", "coding")
    assert p1["interests"].include?("coding")
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving","coding"], p1["interests"]
    
    p1["interests"] = "foo"
    assert_raises(Mongomatic::Modifiers::UnexpectedFieldType) { p1.push("interests", "snowboarding") }
  end
  
  def test_push_into_embedded_hash
    p1 = Person.new(:name => "Jordan")
    p1.insert
    assert p1.push!("personal.interests", "skydiving")
    assert_equal ["skydiving"], p1["personal"]["interests"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving"], p1["personal"]["interests"]
  end
  
  def test_push_all
    p1 = Person.new(:name => "Jordan")
    p1.insert
    assert p1.push("interests", "skydiving")
    assert p1["interests"].include?("skydiving")
    p1 = Person.find_one(p1["_id"])
    assert p1["interests"].include?("skydiving")
   
    assert p1.push_all!("interests", ["coding","running","snowboarding","reading"])
    assert_equal ["skydiving","coding","running","snowboarding","reading"], p1["interests"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving","coding","running","snowboarding","reading"], p1["interests"]
    
    p1["interests"] = "foo"
    assert_raises(Mongomatic::Modifiers::UnexpectedFieldType) { p1.push_all("interests", ["snowboarding"]) }
  end
  
  def test_push_all_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    p1.insert
    p1.push_all!("contacts.coworkers", ["Chris","Keith","Jordan","Mike"])
    assert_equal ["Chris","Keith","Jordan","Mike"], p1["contacts"]["coworkers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["Chris","Keith","Jordan","Mike"], p1["contacts"]["coworkers"]
  end
  
  def test_pull
    p1 = Person.new(:name => "Jordan")
    p1.insert
    assert p1.push("interests", "skydiving")
    assert p1.push_all!("interests", ["coding","running","snowboarding","reading"])
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving","coding","running","snowboarding","reading"], p1["interests"]
    assert p1.pull!("interests", "running")
    assert_equal ["skydiving","coding","snowboarding","reading"], p1["interests"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving","coding","snowboarding","reading"], p1["interests"]
   
    p1["interests"] = "foo"
    assert_raises(Mongomatic::Modifiers::UnexpectedFieldType) { p1.pull("interests", ["snowboarding"]) }
  end
  
  def test_pull_from_embedded_hash
    p1 = Person.new(:name => "Jordan")
    p1.insert!
    p1.push_all!("contacts.coworkers", ["Chris","Keith","Jordan","Mike","Joe"])
    assert_equal ["Chris","Keith","Jordan","Mike","Joe"], p1["contacts"]["coworkers"]
    p1.pull!("contacts.coworkers", "Joe")
    assert_equal ["Chris","Keith","Jordan","Mike"], p1["contacts"]["coworkers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["Chris","Keith","Jordan","Mike"], p1["contacts"]["coworkers"]
  end
  
  def test_pull_all
    p1 = Person.new(:name => "Jordan")
    p1.insert
    assert p1.push_all!("interests", ["skydiving", "coding","running","snowboarding","reading"])
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving","coding","running","snowboarding","reading"], p1["interests"]
    p1.pull_all!("interests", ["running", "snowboarding"])
    assert_equal ["skydiving", "coding","reading"], p1["interests"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["skydiving", "coding","reading"], p1["interests"]
   
    p1["interests"] = "foo"
    assert_raises(Mongomatic::Modifiers::UnexpectedFieldType) { p1.pull_all("interests", ["snowboarding"]) }
  end
  
  def test_pull_all_from_embedded_hash
    p1 = Person.new(:name => "Jordan")
    p1.insert!
    p1.push_all!("contacts.coworkers", ["Chris","Jim","Keith","Jordan","Mike","Joe"])
    assert_equal ["Chris","Jim","Keith","Jordan","Mike","Joe"], p1["contacts"]["coworkers"]
    p1.pull_all!("contacts.coworkers", ["Joe","Jim"])
    assert_equal ["Chris","Keith","Jordan","Mike"], p1["contacts"]["coworkers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["Chris","Keith","Jordan","Mike"], p1["contacts"]["coworkers"]
  end
  
  def test_inc
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    p1["count1"] = 5
    assert p1.update!
    assert p1.inc!("count1", 3)
    assert p1.inc!("count2", -4)
    assert_equal 8, p1["count1"]
    assert_equal -4, p1["count2"]
    p1 = Person.find_one(p1["_id"])
    assert_equal 8, p1["count1"]
    assert_equal -4, p1["count2"]
  end
  
  def test_inc_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    p1.inc!("counters.visitors", 10)
    p1.inc!("level1.level2.level3.counter", 20)
    assert_equal 10, p1["counters"]["visitors"]
    assert_equal 20, p1["level1"]["level2"]["level3"]["counter"]
    p1 = Person.find_one(p1["_id"])
    assert_equal 10, p1["counters"]["visitors"]
    assert_equal 20, p1["level1"]["level2"]["level3"]["counter"]
  end
  
  def test_set
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    assert p1.set!("foo", "bar")
    assert_equal "bar", p1["foo"]
    p1 = Person.find_one(p1["_id"])
    assert_equal "bar", p1["foo"]
  end
  
  def test_set_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    p1.set!("l1.l2.l3.l4.name", "Ben")
    assert_equal "Ben", p1["l1"]["l2"]["l3"]["l4"]["name"]
    p1 = Person.find_one(p1["_id"])
    assert_equal "Ben", p1["l1"]["l2"]["l3"]["l4"]["name"]
  end
  
  def test_unset
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    assert p1.set!("foo", "bar")
    assert_equal "bar", p1["foo"]
    p1 = Person.find_one(p1["_id"])
    assert_equal "bar", p1["foo"]
    
    assert p1.unset!("foo")
    assert p1["foo"].nil?
    p1 = Person.find_one(p1["_id"])
    assert p1["foo"].nil?
  end
  
  def test_unset_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    p1.set!("l1.l2.l3.l4.name", "Ben")
    assert_equal "Ben", p1["l1"]["l2"]["l3"]["l4"]["name"]
    p1 = Person.find_one(p1["_id"])
    assert_equal "Ben", p1["l1"]["l2"]["l3"]["l4"]["name"]
    assert p1["l1"]["l2"]["l3"]["l4"].has_key?("name")

    p1.unset!("l1.l2.l3.l4.name")
    assert_equal nil, p1["l1"]["l2"]["l3"]["l4"]["name"]
    assert !p1["l1"]["l2"]["l3"]["l4"].has_key?("name")
    
    p1 = Person.find_one(p1["_id"])
    assert_equal nil, p1["l1"]["l2"]["l3"]["l4"]["name"]
    assert !p1["l1"]["l2"]["l3"]["l4"].has_key?("name")
  end
  
  def test_add_to_set
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    
    assert p1.add_to_set!("hot_colors", "red")
    assert p1.add_to_set!("cold_colors", ["grey","blue"])
    
    assert_equal ["red"], p1["hot_colors"]
    assert_equal ["grey","blue"], p1["cold_colors"]
    
    p1 = Person.find_one(p1["_id"])

    assert_equal ["red"], p1["hot_colors"]
    assert_equal ["grey","blue"], p1["cold_colors"]
  end
  
  def test_add_to_set_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    assert p1.insert!
    p1.add_to_set!("colors.hot", ["red", "pink", "orange"])
    assert_equal ["red", "pink", "orange"], p1["colors"]["hot"]
    p1 = Person.find_one(p1["_id"])
    assert_equal ["red", "pink", "orange"], p1["colors"]["hot"]
  end
  
  def test_pop_last
    p1 = Person.new(:name => "Jordan")
    p1["numbers"] = [1,2,3,4,5]
    assert p1.insert!
    p1.pop_last!("numbers")
    assert_equal [1,2,3,4], p1["numbers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal [1,2,3,4], p1["numbers"]
  end
  
  def test_pop_last_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    p1["stats"] = { "numbers" => [1,2,3,4,5] }
    assert p1.insert!
    p1.pop_last!("stats.numbers")
    assert_equal [1,2,3,4], p1["stats"]["numbers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal [1,2,3,4], p1["stats"]["numbers"]
  end
  
  def test_pop_first
    p1 = Person.new(:name => "Jordan")
    p1["numbers"] = [1,2,3,4,5]
    assert p1.insert!
    p1.pop_first!("numbers")
    assert_equal [2,3,4,5], p1["numbers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal [2,3,4,5], p1["numbers"]
  end
  
  def test_pop_first_in_embedded_hash
    p1 = Person.new(:name => "Jordan")
    p1["stats"] = { "numbers" => [1,2,3,4,5] }
    assert p1.insert!
    p1.pop_first!("stats.numbers")
    assert_equal [2,3,4,5], p1["stats"]["numbers"]
    p1 = Person.find_one(p1["_id"])
    assert_equal [2,3,4,5], p1["stats"]["numbers"]
  end
  
  def test_chainable_modifiers_as_block
    p1 = Person.new(:name => "Jordan").insert
    p1 = Person.find_one(p1)
    
    p1.start_modifier_chain do |p|
      p.push_all('friends', [12345, 456])
      p.inc('num_friends', 2)
      p.inc('connections', 2)
      p.set('fbid', 98)
    end
    
    assert_equal [12345, 456], p1['friends']
    assert_equal 2, p1['num_friends']
    assert_equal 2, p1['connections']
    assert_equal 98, p1['fbid']
    
    class << p1
      def do_something_cool(tester)
        start_modifier_chain do 
          inc('num_friends', 3)
          tester.assert_equal 2, self['num_friends']
          
          set('connections', 5)
          tester.assert_equal 2, self['connections']
          
          push('pets', 'Nola')
          tester.assert_equal nil, self['pets']
          
          push_all('interests1', ['interest1', 'interest2'])
          push_all('interests2', ['interest3', 'interest4'])
          push_all('interests3', ['interest5', 'interest6', 'interest7'])
          
          pull('friends', 12345)
          tester.assert_equal [12345, 456], self['friends']
          
          unset('fbid')
          tester.assert_equal 98, self['fbid']
        end 
      end
    end
    p1.do_something_cool(self)
    
    assert_equal 5, p1['num_friends']
    assert_equal 5, p1['connections']
    assert_equal ['Nola'], p1['pets']
    assert_equal [456], p1['friends']
    assert_equal nil, p1['fbid']
    
    class << p1
      def do_another_thing(tester)
        start_modifier_chain do
          add_to_set('computers', ['MBP', 'MBA'])
          tester.assert_equal nil, self['computers']
          
          pop_last('interests1')
          tester.assert_equal ['interest1', 'interest2'], self['interests1']
          
          pop_first('interests2')
          tester.assert_equal ['interest3', 'interest4'], self['interests2']
          
          pull_all('interests3', ['interest5', 'interest6'])
          tester.assert_equal ['interest5', 'interest6', 'interest7'], self['interests3']
        end
      end
    end
    p1.do_another_thing(self)
    
    assert_equal ['MBP', 'MBA'], p1['computers']
    assert_equal ['interest1'], p1['interests1']
    assert_equal ['interest4'], p1['interests2']
    assert_equal ['interest7'], p1['interests3']
  end
  
  def test_chainable_modifiers_as_simple_chain
    p1 = Person.new(:name => "Jordan").insert
    p1 = Person.find_one(p1)
    
    p1.start_modifier_chain.push_all(
      'friends', [12345, 456]
    ).inc('num_friends', 2).inc('connections', 2).flush_modifier_chain
    
    assert_equal [12345, 456], p1['friends']
    assert_equal 2, p1['num_friends']
    assert_equal 2, p1['connections']
  end
  
  def test_chainable_modifers_as_sequential_chain
    p1 = Person.new(:name => "Jordan").insert
    p1 = Person.find_one(p1)
    
    p1.start_modifier_chain
    p1.push_all('friends', [12345, 456])
    assert_equal nil, p1['friends']
    
    p1.inc('num_friends', 2)
    assert_equal nil, p1['num_friends']
    
    p1.inc('connections', 2)
    assert_equal nil, p1['connections']
    
    p1.flush_modifier_chain
    
    assert_equal [12345, 456], p1['friends']
    assert_equal 2, p1['num_friends']
    assert_equal 2, p1['connections']
  end
  
  def test_chainable_defaults_to_safe_if_one_is_safe
    p1 = Person.new(:name => "Jordan").insert
    p1 = Person.find_one(p1)
    
    assert_raises(Mongo::OperationFailure) do
      p1.start_modifier_chain do |p|
        p.push('friends', 'abc')
        p.pull!('friends', 'def')
        p.inc('connections', 0)
      end
    end
  end
  
  def test_chainable_defaults_to_unsafe
    p1 = Person.new(:name => "Jordan").insert
    p1 = Person.find_one(p1)
    
    p1.start_modifier_chain do |p|
      p.push('friends', 'abc')
      p.pull('friends', 'def')
    end
  end
  
end