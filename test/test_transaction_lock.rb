require 'helper'
require 'minitest/autorun'

class TestTransactionLock < MiniTest::Unit::TestCase
  def setup
    Person.collection.drop
  end
  
  def test_transaction
    p1 = Person.new(:name => "Jordan")
    p1.insert
    p1.transaction do
      puts "in txn"
    end
    assert true
  end
end
