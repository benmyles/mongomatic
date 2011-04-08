require 'helper'
require 'minitest/autorun'

class MyCoolCallbacks < Mongomatic::Observer
end

class ThingObserver < Mongomatic::Observer
end

module A
  class FoobarObserver < Mongomatic::Observer
    class << self
      attr_accessor :observable_instance, :observer_opts
      
      def observer_tests
        @observer_tests || []
      end
  
      def add_observer_test_val(val)
        @observer_tests ||= []
        @observer_tests << val
      end
    end
  
    def do_something(instance, opts)
      self.class.observer_opts = opts
      self.class.add_observer_test_val(:do_something)
    end
  
    def before_validate(instance, opts)
      self.class.observable_instance = instance
      self.class.add_observer_test_val(:before_validate)
    end
  
    def after_validate(instance, opts)
      self.class.add_observer_test_val(:after_validate)
    end
  
    def before_insert(instance, opts)
      self.class.add_observer_test_val(:before_insert)
    end
  
    def before_insert_or_update(instance, opts)
      self.class.add_observer_test_val(:before_insert_or_update)
    end
  
    def after_insert_or_update(instance, opts)
      self.class.add_observer_test_val(:after_insert_or_update)
    end
  
    def after_insert(instance, opts)
      self.class.add_observer_test_val(:after_insert)
    end

    def before_update(instance, opts)
      self.class.add_observer_test_val(:before_update)
    end
  
    def after_update(instance, opts)
      self.class.add_observer_test_val(:after_update)
    end
  
    def before_remove(instance, opts)
      self.class.add_observer_test_val(:before_remove)
    end
  
    def after_remove(instance, opts)
      self.class.add_observer_test_val(:after_remove)
    end
  end
end

class TestObservable < MiniTest::Unit::TestCase
  def test_add_observer_to_class
    Person.send(:include, Mongomatic::Observable)
    Person.remove_observers
    
    assert_equal [], Person.observers
    
    Person.add_observer(MyCoolCallbacks)
    assert_equal Person.observers, [:MyCoolCallbacks]
  end
  
  def test_add_observer_to_class_as_symbol
    Person.send(:include, Mongomatic::Observable)
    Person.remove_observers
    
    assert_equal [], Person.observers
    Person.add_observer(:MyCoolCallbacks)
    
    assert_equal Person.observers, [:MyCoolCallbacks]
  end
  
  def test_add_observer_using_directive
     assert_equal Foobar.observers, ["A::FoobarObserver".to_sym]
  end
  
  def test_does_not_bomb_with_nonexistent_observer
    Person.send(:include, Mongomatic::Observable)
    Person.remove_observers
    
    Person.add_observer(:DoesNotExist)
    p = Person.new
    
    p.valid?
  end
  
  def test_passes_instance_to_observer
    f = Foobar.new
    f.valid?
    
    assert_equal f, A::FoobarObserver.observable_instance
  end
  
  def test_before_validate
    f = Foobar.new
    f.valid?
    
    assert A::FoobarObserver.observer_tests.include?(:before_validate)
  end
  
  def test_after_validate
    f = Foobar.new
    f.valid?
    
    assert A::FoobarObserver.observer_tests.include?(:after_validate)
  end
  
  def test_before_insert
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    
    assert A::FoobarObserver.observer_tests.include?(:before_insert)
  end
  
  def test_after_insert
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    
    assert A::FoobarObserver.observer_tests.include?(:after_insert)
  end
  
  def test_before_insert_or_update
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    
    assert A::FoobarObserver.observer_tests.include?(:before_insert_or_update)
  end
  
  def test_after_insert_or_update
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    
    assert A::FoobarObserver.observer_tests.include?(:after_insert_or_update)
  end
  
  def test_before_update
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    f.update
    
    assert A::FoobarObserver.observer_tests.include?(:before_update)
  end
  
  def test_after_update
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    f.update
    
    assert A::FoobarObserver.observer_tests.include?(:after_update)
  end
  
  def test_before_remove
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    f.remove
    
    assert A::FoobarObserver.observer_tests.include?(:before_remove)
  end
  
  def test_after_remove
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    f.insert
    f.remove
    
    assert A::FoobarObserver.observer_tests.include?(:after_remove)
  end
  
  def test_custom_callback
    opts = {:a => 1234}
    f = Foobar.new('style' => 'cool', 'color' => 'green')
    class << f
      def do_something
        notify(:do_something, {:a => 1234})
      end
    end
    f.do_something
    
    assert A::FoobarObserver.observer_tests.include?(:do_something)
    assert_equal opts, A::FoobarObserver.observer_opts
  end
end
