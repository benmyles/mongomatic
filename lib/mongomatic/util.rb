module Mongomatic
  module Util
    def create_array(val)
      val.is_a?(Array) ? val : [val]
    end
  end
end