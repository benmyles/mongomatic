require 'helper'
require 'minitest/autorun'

class TestFields < MiniTest::Unit::TestCase
  def setup
    Rig.collection.drop
  end

  def test_raising_error_on_invalid_type
    r = Rig.new
    assert r["manufacturer"].blank?
    r["manufacturer"] = { "phone" => 123 }
    assert_raises(Mongomatic::Fields::InvalidField) { r.valid? }
    r["manufacturer"] = {}
    r["manufacturer"]["phone"] = "(800) 123 456 789"
    assert_equal true, r.valid?
    assert_equal "(800) 123 456 789", r["manufacturer"]["phone"]
  end
  
  def test_cast_string
    r = Rig.new
    r["manufacturer"] = {}
    r["manufacturer"]["name"] = ["Wings","Parachuting","Company"]
    assert_equal ["Wings","Parachuting","Company"], r["manufacturer"]["name"]
    assert r.valid?
    assert_equal ["Wings","Parachuting","Company"].to_s, r["manufacturer"]["name"]
  end
  
  def test_cast_number
    r = Rig.new
    r["age"] = "4"
    assert_equal "4", r["age"]
    assert r.valid?
    assert_equal 4, r["age"]
  end
  
  def test_cast_float
    r = Rig.new
    r["waist_measurement"] = "34.3"
    assert_equal "34.3", r["waist_measurement"]
    assert r.valid?
    assert_equal 34.3, r["waist_measurement"]
  end
end