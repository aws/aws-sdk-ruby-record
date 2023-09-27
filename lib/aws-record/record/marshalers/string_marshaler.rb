# frozen_string_literal: true

module Aws
  module Record
    module Marshalers
      class StringMarshaler
        def initialize(opts = {})
          # pass
        end

        def type_cast(raw_value)
          case raw_value
          when nil
            nil
          when String
            raw_value
          else
            raw_value.to_s
          end
        end

        def serialize(raw_value)
          value = type_cast(raw_value)
          if value.is_a?(String)
            if value.empty?
              nil
            else
              value
            end
          elsif value.nil?
            nil
          else
            msg = "expected a String value or nil, got #{value.class}"
            raise ArgumentError, msg
          end
        end
      end
    end
  end
end
