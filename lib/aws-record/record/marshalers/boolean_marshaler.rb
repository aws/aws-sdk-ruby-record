# frozen_string_literal: true

module Aws
  module Record
    module Marshalers
      class BooleanMarshaler
        def initialize(opts = {})
          # pass
        end

        def type_cast(raw_value)
          case raw_value
          when nil, ''
            nil
          when false, 'false', '0', 0
            false
          else
            true
          end
        end

        def serialize(raw_value)
          boolean = type_cast(raw_value)
          case boolean
          when nil
            nil
          when false
            false
          when true
            true
          else
            msg = "expected a boolean value or nil, got #{boolean.class}"
            raise ArgumentError, msg
          end
        end
      end
    end
  end
end
