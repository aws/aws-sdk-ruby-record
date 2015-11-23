module Aws
  module Record
    module Base
      def self.included(sub_class)
        sub_class.include(Attributes)
      end
    end
  end
end
