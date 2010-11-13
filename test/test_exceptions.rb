require 'helper'
require 'minitest/autorun'

class TestExceptions < MiniTest::Unit::TestCase
  def setup
    Person.collection.drop
  end
  
  def test_raise_on_update_of_new_doc
    p1 = Person.new(:name => "Jordan")
    assert_equal false, p1.update
    assert_raises(Mongomatic::Exceptions::DocumentIsNew) { p1.update(:raise => true) }
  end
  
  def test_raise_on_insert_of_invalid_doc
    p1 = Person.new
    assert_equal false, p1.insert
    assert_raises(Mongomatic::Exceptions::DocumentNotValid) { p1.insert(:raise => true) }
  end
  
  def test_raise_on_update_of_invalid_doc
    p1 = Person.new(:name => "Ben")
    assert p1.insert
    p1["name"] = nil
    assert_equal false, p1.update
    assert_raises(Mongomatic::Exceptions::DocumentNotValid) { p1.update(:raise => true) }
  end
  
  def test_raise_on_update_or_insert_after_remove
    p1 = Person.new(:name => "Ben")
    assert p1.insert
    assert p1.remove
    assert_raises(Mongomatic::Exceptions::DocumentWasRemoved) { p1.remove(:raise => true) }
    assert_raises(Mongomatic::Exceptions::DocumentWasRemoved) { p1.update(:raise => true) }
    assert_raises(Mongomatic::Exceptions::DocumentWasRemoved) { p1.insert(:raise => true) }
  end
end