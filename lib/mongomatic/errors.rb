module Mongomatic
  class Errors < Array
    def full_messages(sep=" ")
      collect { |e| e.join(sep) }
    end
  end
end