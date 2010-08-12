require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'pp'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongomatic'

Mongomatic.db = Mongo::Connection.new.db("mongomatic_test")

class Person < Mongomatic::Base
  validates_presence_of :name
  attr_accessor :callback_tests
  
  def self.create_indexes
    collection.create_index("name", :unique => true)
  end
  
  def before_validate
    self.callback_tests ||= []
    self.callback_tests << :before_validate
  end
  
  def after_validate
    self.callback_tests ||= []
    self.callback_tests << :after_validate
  end
  
  def before_insert
    self.callback_tests ||= []
    self.callback_tests << :before_insert
  end
  
  def before_insert_or_update
    self.callback_tests ||= []
    self.callback_tests << :before_insert_or_update
  end
  
  def after_insert_or_update
    self.callback_tests ||= []
    self.callback_tests << :after_insert_or_update
  end
  
  def after_insert
    self.callback_tests ||= []
    self.callback_tests << :after_insert
  end

  def before_update
    self.callback_tests ||= []
    self.callback_tests << :before_update
  end
  
  def after_update
    self.callback_tests ||= []
    self.callback_tests << :after_update
  end
  
  def before_remove
    self.callback_tests ||= []
    self.callback_tests << :before_remove
  end
  
  def after_remove
    self.callback_tests ||= []
    self.callback_tests << :after_remove
  end
  
end

class Test::Unit::TestCase
end
