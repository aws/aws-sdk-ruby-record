module Aws
  module Record
    class NullValidation
      def initialize(record)
      end

      def validate!
        yield
      end

      def valid?
        true
      end
    end
  end
end
