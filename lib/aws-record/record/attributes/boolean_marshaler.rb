module Aws
  module Record
    module Attributes
      module BooleanMarshaler

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              nil
            when ''
              nil
            when false, 'false', '0', 0
              false
            else
              true
            end
          end

          def serialize(raw_value, options = {})
            boolean = type_cast(raw_value, options)
            case boolean
            when nil
              { null: true }
            when false
              { bool: false }
            when true
              { bool: true }
            else
              msg = "expected a boolean value or nil, got #{boolean.class}"
              raise ArgumentError, msg
            end
          end

        end

      end
    end
  end
end
