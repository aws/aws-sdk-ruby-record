# frozen_string_literal: true

module Aws
  module Record
    module Marshalers
      class FloatMarshaler
        def initialize(opts = {})
          # pass
        end

        def type_cast(raw_value)
          case raw_value
          when nil, ''
            nil
          when Float
            raw_value
          else
            raw_value.respond_to?(:to_f) ? raw_value.to_f : raw_value.to_s.to_f
          end
        end

        def serialize(raw_value)
          float = type_cast(raw_value)
          if float.nil?
            nil
          elsif float.is_a?(Float)
            float
          else
            msg = "expected a Float value or nil, got #{float.class}"
            raise ArgumentError, msg
          end
        end
      end
    end
  end
end
