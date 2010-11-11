require 'helper'

class TestExceptions < Test::Unit::TestCase
  def setup
    Person.collection.drop
  end
  
  should "raise on updating new document" do
    p1 = Person.new(:name => "Jordan")
    assert_equal false, p1.update
    assert_raise(Mongomatic::Exceptions::DocumentIsNew) { p1.update(:raise => true) }
  end
  
  should "raise on inserting invalid document" do
    p1 = Person.new
    assert_equal false, p1.insert
    assert_raise(Mongomatic::Exceptions::DocumentNotValid) { p1.insert(:raise => true) }
  end
  
  should "raise on updating invalid document" do
    p1 = Person.new(:name => "Ben")
    assert p1.insert
    p1["name"] = nil
    assert_equal false, p1.update
    assert_raise(Mongomatic::Exceptions::DocumentNotValid) { p1.update(:raise => true) }
  end
  
  should "raise on remove" do
    p1 = Person.new(:name => "Ben")
    assert p1.insert
    assert p1.remove
    assert_raise(Mongomatic::Exceptions::DocumentWasRemoved) { p1.remove(:raise => true) }
    assert_raise(Mongomatic::Exceptions::DocumentWasRemoved) { p1.update(:raise => true) }
    assert_raise(Mongomatic::Exceptions::DocumentWasRemoved) { p1.insert(:raise => true) }
  end
end