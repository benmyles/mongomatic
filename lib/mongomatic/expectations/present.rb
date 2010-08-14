class Present < Mongomatic::Expectations::Expectation
  def initialize(instance, value, message)
    @value = value
    @instance = instance
    @message = message
  end
  
  def to_be
    @instance.errors << [@message] if @value.blank?
  end
  
  def to_not_be
    @instance.errors << [@message] unless @value.blank?
  end
end