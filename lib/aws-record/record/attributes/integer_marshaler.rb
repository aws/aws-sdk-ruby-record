module Aws
  module Record
    module Attributes
      module IntegerMarshaler

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              nil
            when ''
              nil
            when Integer
              raw_value
            else
              raw_value.respond_to?(:to_i) ?
                raw_value.to_i :
                raw_value.to_s.to_i
            end
          end

          def serialize(raw_value, options = {})
            integer = type_cast(raw_value, options = {})
            if integer.nil?
              { null: true }
            else
              { n: integer }
            end
          end

        end

      end
    end
  end
end
