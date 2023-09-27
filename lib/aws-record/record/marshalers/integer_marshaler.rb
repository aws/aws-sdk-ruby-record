# frozen_string_literal: true

module Aws
  module Record
    module Marshalers
      class IntegerMarshaler
        def initialize(opts = {})
          # pass
        end

        def type_cast(raw_value)
          case raw_value
          when nil, ''
            nil
          when Integer
            raw_value
          else
            raw_value.respond_to?(:to_i) ? raw_value.to_i : raw_value.to_s.to_i
          end
        end

        def serialize(raw_value)
          integer = type_cast(raw_value)
          if integer.nil?
            nil
          elsif integer.is_a?(Integer)
            integer
          else
            msg = "expected an Integer value or nil, got #{integer.class}"
            raise ArgumentError, msg
          end
        end
      end
    end
  end
end
