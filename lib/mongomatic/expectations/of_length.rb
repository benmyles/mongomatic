class OfLength < Mongomatic::Expectations::Expectation
  def self.name
    "of_length"
  end
  
  def to_be
    return true if opts[:allow_nil] && value.nil?
    
    length = (value) ? value.size : value.to_s.size
    add_error_msg if opts[:minimum] && length < opts[:minimum]
    add_error_msg if opts[:maximum] && length > opts[:maximum]
    if opts[:range]
      add_error_msg unless opts[:range].include?(length)
    end  
  end
end 