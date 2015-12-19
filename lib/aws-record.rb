require 'aws-sdk-resources'

module Aws
  autoload :Record, 'aws-record/record'

  module Record
    autoload :Attribute,      'aws-record/record/attribute'
    autoload :Attributes,     'aws-record/record/attributes'
    autoload :Errors,         'aws-record/record/errors'
    autoload :ItemOperations, 'aws-record/record/item_operations'
    autoload :VERSION,        'aws-record/record/version'

    module Attributes
      autoload :StringMarshaler,   'aws-record/record/attributes/string_marshaler'
      autoload :BooleanMarshaler,  'aws-record/record/attributes/boolean_marshaler'
      autoload :IntegerMarshaler,  'aws-record/record/attributes/integer_marshaler'
      autoload :FloatMarshaler,    'aws-record/record/attributes/float_marshaler'
      autoload :DateMarshaler,     'aws-record/record/attributes/date_marshaler'
      autoload :DateTimeMarshaler, 'aws-record/record/attributes/date_time_marshaler'
    end

  end
end
