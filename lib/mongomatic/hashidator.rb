module Mongomatic
  class Hashidator
    def self.validate(schema, input)
      new(schema).validate(input)
    end

    attr_accessor :schema, :errors

    def initialize(schema)
      @schema = schema
      @errors = []
    end

    def validate(input)
      # refactor, can't use all!
      schema.all? {|key, validator|
        validate_value(validator, input[key])
      }
    end

    private

    def validate_value(validator, value)
      case validator
      when Range
        # finish doing this stuff so we populate @errors
        res = validator.include?(value)
        @errors << validator unless res; res
      when Array
        value.all? {|x| validate_value(validator[0], x)}
      when Symbol
        value.respond_to? validator
      when Regexp
        value.match validator
      when Hash
        Hashidator.validate(validator, value)
      when Class, Module
        value.is_a? validator
      when Proc
        result = validator.call(value)
        result = validate_value(result, value) unless Boolean === result
        result
      end
    end
  end
end

module Boolean
end

class TrueClass
  include Boolean
end

class FalseClass
  include Boolean
end