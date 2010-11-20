require 'rubygems'
gem 'minitest', "~> 2.0"
require 'pp'

# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))
require "#{File.dirname(__FILE__)}/../lib/mongomatic"
#require 'mongomatic'

Mongomatic.db = Mongo::Connection.new.db("mongomatic_test")

class Person < Mongomatic::Base
  include Mongomatic::Expectations::Helper
  include Mongomatic::ChainableModifiers
  attr_accessor :callback_tests
  
  class << self
    attr_accessor :class_callbacks
    def create_indexes
      collection.create_index("name", :unique => true)
    end

    def before_drop
      self.class_callbacks ||= []
      self.class_callbacks << :before_drop
    end

    def after_drop
      self.class_callbacks ||= []
      self.class_callbacks << :after_drop
    end
  end

  def validate
    self.errors.add "name", "can't be empty" if self["name"].blank?
  end
  
  private
  
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

class Thing < Mongomatic::Base
  def before_insert
    raise NoMethodError
  end

  def self.before_drop
    raise NoMethodError
  end
end

class Foobar < Mongomatic::Base
  include Mongomatic::Observable
  observer :FoobarObserver
  
  def validate
    errors << ["color", "must not be blank"] if self["color"].blank?
    errors << "missing style" if self["style"].blank?
  end
end

class RigObserver < Mongomatic::Observer
end

class Rig < Mongomatic::Base
  include Mongomatic::Observable
  
  # :cast => true, :raise => false is the default
  typed_field "age",                :type => :fixnum,  :cast => true
  typed_field "manufacturer.name",  :type => :string,  :cast => true
  typed_field "manufacturer.phone", :type => :string,  :cast => false
  typed_field "waist_measurement",  :type => :float,   :cast => true
  typed_field "friends_rig_id",     :type => :object_id, :cast => true
end



