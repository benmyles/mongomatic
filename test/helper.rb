require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'pp'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongomatic'

Mongomatic.settings = { :connection => ["localhost", 27017, {}], :db => "mongomatic_test" }

class Person < Mongomatic::Base
  validates_presence_of :name
end

class Test::Unit::TestCase
end
