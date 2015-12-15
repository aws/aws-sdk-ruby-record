module Aws
  module Record
    def self.included(sub_class)
      sub_class.extend(RecordClassMethods)
      sub_class.include(Attributes)
      sub_class.include(ItemOperations)
    end

    module RecordClassMethods
      def table_name
        if @table_name
          @table_name
        else
          @table_name = self.name
        end
      end

      def set_table_name(name)
        @table_name = name
      end
    end
  end
end
