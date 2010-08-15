class Expected < Mongomatic::Expectations::Expectation
  def to_be
    add_error_msg unless value
  end

  def to_not_be
    add_error_msg if value
  end
end