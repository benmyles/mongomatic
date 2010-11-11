module Mongomatic
  module ActiveModelCompliancy

    def to_model
      self
    end
    
    def new_record?
      new?
    end
    
    def destroyed?
      removed?
    end
    
    def persisted?
      !new?
    end
    
    def to_key
      self["_id"]
    end
    
    def to_param
      self["_id"] ? self["_id"].to_s : nil
    end

  end
end