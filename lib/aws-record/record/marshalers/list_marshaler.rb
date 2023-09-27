# frozen_string_literal: true

module Aws
  module Record
    module Marshalers
      class ListMarshaler
        def initialize(opts = {})
          # pass
        end

        def type_cast(raw_value)
          case raw_value
          when nil, ''
            nil
          when Array
            raw_value
          else
            if raw_value.respond_to?(:to_a)
              raw_value.to_a
            else
              msg = "Don't know how to make #{raw_value} of type " \
                    "#{raw_value.class} into an array!"
              raise ArgumentError, msg
            end
          end
        end

        def serialize(raw_value)
          list = type_cast(raw_value)
          if list.is_a?(Array)
            list
          elsif list.nil?
            nil
          else
            msg = "expected an Array value or nil, got #{list.class}"
            raise ArgumentError, msg
          end
        end
      end
    end
  end
end
