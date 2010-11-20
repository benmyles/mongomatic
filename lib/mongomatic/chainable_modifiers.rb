module Mongomatic
  module ChainableModifiers
    def self.included(klass)
      klass.instance_eval do 
        [:push, :push_all, :pull, :pull_all, :inc, :set].each do |mod|
          
          # TODO test on 1.8 solution may be to use ||
          define_method(mod) do |field, val, update_opts={}, safe=false|
            case meth = get_modifier_meth(mod) 
            when :super
              super(field, val, update_opts, safe)
            else
              send(meth, field, val, update_opts, safe)
            end
          end
          
          # TODO test on 1.8 solution may be to use ||
          define_method("chain_#{mod}".to_sym) do |field, val, update_opts={}, safe=false|
            chain_modifier(symbol_to_mongo_mod(mod), field, val, update_opts, safe)
            self
          end
        end

      end
    end
    
    def start_modifier_chain
      # add while(:flushing) check here?
      @modifier_state = :chain
      @modifier_buffer = {}

      if block_given?
        yield(self)
        flush_modifier_chain
      end

      self
    end

    def flush_modifier_chain
      @modifier_state = :flush
      op, update_opts = prepare_modifier_flush(@modifier_buffer)
      update(update_opts, op)
      reload
      @modifier_state = nil
    end
    
    def unset(field, update_opts = {}, safe=false)
      case meth = get_modifier_meth(:unset) 
      when :super
        super(field, update_opts, safe)
      else
        send(meth, field, update_opts, safe)
      end
    end
    
    private
    
    def prepare_modifier_flush(buffer)
      prepared_buffer = {}
      update_opts = {}
      buffer.each do |op, fields|
        prepared_buffer[op] ||= {}
        fields.each do |field, data|
          prepared_buffer[op][field] = data[:val]
          update_opts.merge!(data[:update_opts])
        end
      end
      [prepared_buffer, update_opts]
    end

    def chain_modifier(mod, field, val, update_opts={}, safe=false)
      @modifier_buffer[mod] ||= {}
      @modifier_buffer[mod][field] = {:val => val, 
                                      :update_opts => update_opts, 
                                      :safe => safe}
    end

    def get_modifier_meth(mod)
      @modifier_state == :chain ? "chain_#{mod}".to_sym : :super
    end
    
    def symbol_to_mongo_mod(mod)
      parts = mod.to_s.split("_")
      first = parts.shift
      parts.map!(&:capitalize)
      "$" + first + parts.join("")
    end
    
    def chain_unset(field, update_opts={}, safe=false)
      chain_modifier("$unset", field, nil, update_opts, safe)
      self
    end
  end
end