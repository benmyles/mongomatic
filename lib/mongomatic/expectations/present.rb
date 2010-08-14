class Present < Mongomatic::Expectations::Expectation
  def to_be
    add_error_msg if value.blank?
  end
  
  def to_not_be
    add_error_msg unless value.blank?
  end
end