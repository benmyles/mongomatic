gem "bson", "~> 1.1"
gem "mongo", "~> 1.1"
gem "activesupport", ">= 2.3.5"

require "bson"
require "mongo"

begin
  require 'active_support/core_ext/object/blank' # newer versions of active_support (>= 3.0)
  require 'active_support/core_ext/hash' # newer versions of active_support (>= 3.0)
rescue LoadError => e
  require 'active_support/all' # support older versions of active_support (<= 2.3.5)
end

module Mongomatic
  class << self
    # Returns an instance of Mongo::DB
    def db
      @db
    end
    
    # Set to an instance of Mongo::DB to be used for all models:
    #  Mongomatic.db = Mongo::Connection.new().db('mydb')
    def db=(obj)
      unless obj.is_a?(Mongo::DB)
        raise(ArgumentError, "Must supply a Mongo::DB object")
      end; @db = obj
    end
  end
end

require "#{File.dirname(__FILE__)}/mongomatic/exceptions"
require "#{File.dirname(__FILE__)}/mongomatic/util"
require "#{File.dirname(__FILE__)}/mongomatic/m_hash"
require "#{File.dirname(__FILE__)}/mongomatic/cursor"
require "#{File.dirname(__FILE__)}/mongomatic/modifiers"
require "#{File.dirname(__FILE__)}/mongomatic/errors"
require "#{File.dirname(__FILE__)}/mongomatic/expectations"
require "#{File.dirname(__FILE__)}/mongomatic/active_model_compliancy"
require "#{File.dirname(__FILE__)}/mongomatic/fields"
require "#{File.dirname(__FILE__)}/mongomatic/base"
