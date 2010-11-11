module Mongomatic
  class Errors
    def initialize
      @errors = HashWithIndifferentAccess.new
    end
    
    def add(field, message)
      @errors[field] ||= []
      @errors[field] << message
    end
    
    def add_to_base(message)
      @errors["base"] ||= []
      @errors["base"] << message
    end
    
    def remove(field, message)
      @errors[field] ||= []
      @errors[field].delete message
    end
    
    def empty?
      !(@errors.any? { |k,v| v && !v.empty? })
    end
    
    def full_messages
      full_messages = []
      @errors.each do |field, messages|
        messages.each do |message|
          msg = []
          msg << field unless field == "base"
          msg << message
          full_messages << msg.join(" ")
        end
      end
      full_messages
    end
    
    def [](field)
      @errors[field] || []
    end
    
    def to_hash
      @errors
    end
    
    def on(field)
      self[field]
    end
  end
end

# module Mongomatic
#   class Errors < Array
#     def full_messages(sep=" ")
#       collect { |e| e.join(sep) }
#     end
#     
#     def on(field, sep=" ")
#       ret = []
#       self.each do |err|
#         ret << err.join(sep) if err.first =~ /^#{field.to_s.split('_').join(' ')}/i 
#       end
#       case ret.size
#       when 0
#         nil
#       when 1
#         ret.first
#       else
#         ret
#       end
#     end
#   end
# end