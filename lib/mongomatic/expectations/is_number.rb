class IsNumber < Mongomatic::Expectations::Expectation
  def self.name
    "a_number"
  end
  
  def to_be
    return true if @opts[:allow_nil] && @value.nil?
    
    @instance.errors << [@message] if (@value.to_s =~ /^\d*\.{0,1}\d+$/).nil?
  end
  
  def to_not_be
    @instance.errors << [@message] unless (@value.to_s =~ /^\d*\.{0,1}\d+$/).nil?
  end
end
