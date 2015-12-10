module Aws
  module Record
    def self.included(sub_class)
      sub_class.include(Attributes)
    end
  end
end
