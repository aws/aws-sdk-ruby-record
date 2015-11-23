module Aws
  module Record
    module Attributes
      module StringMarshaler

        STRING_TYPE = :s
        NULL_TYPE = :null

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              if options[:nil_as_empty_string]
                ''
              else
                nil
              end
            when String
              if raw_value.empty? && !options[:nil_as_empty_string]
                nil
              else
                raw_value
              end
            else
              raw_value.to_s
            end
          end

          def serialize(raw_value, options = {})
             value = type_cast(raw_value)
            if value.is_a?(String)
              if value.empty?
                { null: true }
              else
                { s: value }
              end
            elsif value.nil?
              { null: true }
            else
              msg = "expected a String value or nil, got #{value.class}"
              raise ArgumentError, msg
            end
          end

        end
      end
    end
  end
end
