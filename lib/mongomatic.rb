gem "bson", ">= 1.0.4"
gem "bson_ext", ">= 1.0.4"
gem "mongo", ">= 1.0.7"
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
    def db
      @db
    end
    
    def db=(obj)
      unless obj.is_a?(Mongo::DB)
        raise(ArgumentError, "Must supply a Mongo::DB object")
      end; @db = obj
    end
  end
end

require "#{File.dirname(__FILE__)}/mongomatic/cursor"
require "#{File.dirname(__FILE__)}/mongomatic/modifiers"
require "#{File.dirname(__FILE__)}/mongomatic/errors"
require "#{File.dirname(__FILE__)}/mongomatic/expectations"
require "#{File.dirname(__FILE__)}/mongomatic/base"
