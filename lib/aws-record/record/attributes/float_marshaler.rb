module Aws
  module Record
    module Attributes
      module FloatMarshaler

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              nil
            when ''
              nil
            when Float
              raw_value
            else
              raw_value.respond_to?(:to_f) ?
                raw_value.to_f :
                raw_value.to_s.to_f
            end
          end

          def serialize(raw_value, options = {})
            float = type_cast(raw_value, options = {})
            if float.nil?
              nil
            elsif float.is_a?(Float)
              float
            else
              msg = "expected a Float value or nil, got #{value.class}"
              raise ArgumentError, msg
            end
          end

        end

      end
    end
  end
end
