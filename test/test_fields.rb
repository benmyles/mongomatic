require 'helper'
require 'minitest/autorun'

class TestFields < MiniTest::Unit::TestCase
  def setup
    Rig.collection.drop
  end
  
  def test_has_field_gets_added_to_class
    assert_equal(
      {"manufacturer.name"  => {:cast=>true,  :raise=>false, :type=>:string},
       "manufacturer.phone" => {:cast=>false, :raise=>true,  :type=>:string}},
      Rig.fields)
  end
  
  def test_raising_error_on_invalid_type
    r = Rig.new
    assert r["manufacturer"].blank?
    assert_raises(Mongomatic::Fields::InvalidField) do
      r["manufacturer"] = { "phone" => 123 }
    end
    assert r["manufacturer"].blank?
    r["manufacturer"] = {}
    r["manufacturer"]["phone"] = "(800) 123 456 789"
    assert_equal "(800) 123 456 789", r["manufacturer"]["phone"]
    assert_raises(Mongomatic::Fields::InvalidField) do
      r["manufacturer"] = { "phone" => 123 }
    end
    assert_equal "(800) 123 456 789", r["manufacturer"]["phone"]
  end
  
  def test_casting_to_type
    r = Rig.new
    r["manufacturer"] = {}
    r["manufacturer"]["name"] = ["Wings","Parachuting","Company"]
    puts r["manufacturer"]["name"].class.to_s
    #assert_equal "", r["manufacturer"]["name"]
  end
end