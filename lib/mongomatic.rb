gem "bson", "= 1.0.3"
gem "bson_ext", "= 1.0.1"
gem "mongo", "= 1.0.3"
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
    def settings
      @settings || { :connection => ["localhost", 27017, {}], :db => "main" }
    end

    def settings=(hash)
      @settings = hash
      @db = @collection = nil
      hash
    end
  end
end

require "#{File.dirname(__FILE__)}/mongomatic/validatable"

require "#{File.dirname(__FILE__)}/mongomatic/cursor"
require "#{File.dirname(__FILE__)}/mongomatic/modifiers"
require "#{File.dirname(__FILE__)}/mongomatic/base"
