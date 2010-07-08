# gem "activesupport", "2.3.5"

require "forwardable"

require "#{File.dirname(__FILE__)}/validatable/object_extension"
require "#{File.dirname(__FILE__)}/validatable/errors"
require "#{File.dirname(__FILE__)}/validatable/validatable_class_methods"
require "#{File.dirname(__FILE__)}/validatable/macros"
require "#{File.dirname(__FILE__)}/validatable/validatable_instance_methods"
require "#{File.dirname(__FILE__)}/validatable/included_validation"
require "#{File.dirname(__FILE__)}/validatable/child_validation"
require "#{File.dirname(__FILE__)}/validatable/understandable"
require "#{File.dirname(__FILE__)}/validatable/requireable"
require "#{File.dirname(__FILE__)}/validatable/validations/validation_base"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_format_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_presence_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_acceptance_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_confirmation_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_length_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_true_for"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_numericality_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_exclusion_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_inclusion_of"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_each"
require "#{File.dirname(__FILE__)}/validatable/validations/validates_associated"

module Validatable
  Version = "1.8.4"
end