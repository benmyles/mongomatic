module Mongomatic
  class Errors < Array
    def full_messages(sep=" ")
      collect { |e| e.join(sep) }
    end
    
    def on(field, sep=" ")
      ret = []
      self.each do |err|
        ret << err.join(sep) if err.first =~ /^#{field}/i 
      end
      case ret.size
      when 0
        nil
      when 1
        ret.first
      else
        ret
      end
    end
  end
end