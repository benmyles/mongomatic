require 'helper'
require 'minitest/autorun'

class TestTransactionLock < MiniTest::Unit::TestCase
  def setup
    Person.collection.drop
    Mongomatic::TransactionLock.collection.drop
    Mongomatic::TransactionLock.create_indexes
  end
  
  def test_will_rm_lock_when_complete
    assert_equal 0, Mongomatic::TransactionLock.count
    p1 = Person.new(:name => "Jordan")
    p1.insert!
    p1.transaction { assert_equal 1, Mongomatic::TransactionLock.count }
    assert_equal 0, Mongomatic::TransactionLock.count
    p1.transaction { assert_equal 1, Mongomatic::TransactionLock.count }
  end
  
  def test_will_raise_if_cant_get_lock
    p1 = Person.new(:name => "Jordan")
    p1.insert!
    
    l = Mongomatic::TransactionLock.new(:key => "Person-#{p1["_id"]}", :expire_at => Time.now.utc + 1.day)
    l.insert!
    
    assert_raises(Mongomatic::Exceptions::CannotGetTransactionLock) do
      p1.transaction { true }
    end
    
    assert_raises(Mongomatic::Exceptions::CannotGetTransactionLock) do
      p1.transaction { true }
    end
    
    l.remove!

    p1.transaction { assert_equal 1, Mongomatic::TransactionLock.count }
  end
  
  def test_will_rm_stale_locks
    p1 = Person.new(:name => "Jordan")
    p1.insert!
    
    l = Mongomatic::TransactionLock.new(:key => "Person-#{p1["_id"]}", :expire_at => Time.now.utc - 1.day)
    l.insert!
    
    p1.transaction { assert_equal 1, Mongomatic::TransactionLock.count }
  end
  
  def test_race_condition
    c = Clock.new
    c.insert!
    threads = []

    lock_errors = 0

    50.times do
      threads << Thread.new do
        begin
          Mongomatic.db = Mongo::Connection.new.db("mongomatic_test")
          c = Clock.find_one(c["_id"])
          c.tick!
        rescue Mongomatic::Exceptions::CannotGetTransactionLock => e
          lock_errors += 1
          sleep(0.05); retry
        end
      end
    end
    threads.each { |th| th.join }

    c = Clock.find_one(c["_id"])
    assert_equal 50, c["ticks"]
    
    assert lock_errors > 0
  end
end
