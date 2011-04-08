require 'bson'
require 'mongo'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'

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

require "#{File.dirname(__FILE__)}/mongomatic/observer"
require "#{File.dirname(__FILE__)}/mongomatic/observable"
require "#{File.dirname(__FILE__)}/mongomatic/exceptions"
require "#{File.dirname(__FILE__)}/mongomatic/util"
require "#{File.dirname(__FILE__)}/mongomatic/m_hash"
require "#{File.dirname(__FILE__)}/mongomatic/cursor"
require "#{File.dirname(__FILE__)}/mongomatic/chainable_modifiers"
require "#{File.dirname(__FILE__)}/mongomatic/modifiers"
require "#{File.dirname(__FILE__)}/mongomatic/errors"
require "#{File.dirname(__FILE__)}/mongomatic/expectations"
require "#{File.dirname(__FILE__)}/mongomatic/active_model_compliancy"
require "#{File.dirname(__FILE__)}/mongomatic/type_converters"
require "#{File.dirname(__FILE__)}/mongomatic/typed_fields"
require "#{File.dirname(__FILE__)}/mongomatic/base"
require "#{File.dirname(__FILE__)}/mongomatic/transaction_lock"
