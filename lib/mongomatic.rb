gem "bson", "= 1.0.3"
gem "bson_ext", "= 1.0.1"
gem "mongo", "= 1.0.3"

require "bson"
require "mongo"

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

require "#{File.dirname(__FILE__)}/mongomatic/hashidator"
require "#{File.dirname(__FILE__)}/mongomatic/cursor"
require "#{File.dirname(__FILE__)}/mongomatic/modifiers"
require "#{File.dirname(__FILE__)}/mongomatic/base"
