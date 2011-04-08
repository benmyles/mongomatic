module Mongomatic
  module Exceptions
    class Base < Exception; end
    
    class DocumentNotNew     < Base; end
    class DocumentIsNew      < Base; end
    class DocumentWasRemoved < Base; end
    class DocumentNotValid   < Base; end
    
    class CannotGetTransactionLock < Base; end
  end
end