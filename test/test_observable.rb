require 'helper'
require 'minitest/autorun'

class MyCoolCallbacks < Mongomatic::Observer
end

class FoobarObserver < Mongomatic::Observer
end

class TestObservable < MiniTest::Unit::TestCase
  def test_add_observer_to_class
    Person.send(:include, Mongomatic::Observable)

    assert_equal [], Person.observers
    
    Person.add_observer(MyCoolCallbacks)
    assert_equal Person.observers, [MyCoolCallbacks]
  end
  
  
  def test_add_observer_to_class_when_class_is_inferred_and_module_included_post_load
    assert_equal [RigObserver], Rig.observers
  end
  
  def test_add_observer_to_class_when_class_is_inferred_and_module_included_pre_load
    assert_equal [FoobarObserver], Foobar.observers
  end
end