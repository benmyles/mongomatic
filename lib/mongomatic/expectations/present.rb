class Present < Mongomatic::Expectations::Expectation
  def to_be
    @instance.errors << [@message] if @value.blank?
  end
  
  def to_not_be
    @instance.errors << [@message] unless @value.blank?
  end
end