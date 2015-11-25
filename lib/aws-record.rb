require 'aws-sdk-resources'

module Aws
  module Record
    autoload :Base,       'aws-record/record/base'
    autoload :Attribute,  'aws-record/record/attribute'
    autoload :Attributes, 'aws-record/record/attributes'

    module Attributes
      autoload :StringMarshaler,  'aws-record/record/attributes/string_marshaler'
      autoload :BooleanMarshaler, 'aws-record/record/attributes/boolean_marshaler'
      autoload :IntegerMarshaler, 'aws-record/record/attributes/integer_marshaler'
      autoload :FloatMarshaler,   'aws-record/record/attributes/float_marshaler'
    end

  end
end
