# frozen_string_literal: true

module Aws
  module Record
    module Errors
      # RecordErrors relate to the persistence of items. They include both
      # client errors and certain validation errors.
      class RecordError < RuntimeError; end

      # Raised when a required key attribute is missing from an item when
      # persistence is attempted.
      class KeyMissing < RecordError; end

      # Raised when you attempt to load a record from the database, but it does
      # not exist there.
      class NotFound < RecordError; end

      # Raised when a conditional write fails.
      # Provides access to the original ConditionalCheckFailedException error
      # which may have item data if the return values option was used.
      class ConditionalWriteFailed < RecordError
        def initialize(message, original_error)
          @original_error = original_error
          super(message)
        end

        # @return [Aws::DynamoDB::Errors::ConditionalCheckFailedException]
        attr_reader :original_error
      end

      # Raised when a validation hook call to +:valid?+ fails.
      class ValidationError < RecordError; end

      # Raised when an attribute is defined that has a name collision with an
      # existing attribute.
      class NameCollision < RuntimeError; end

      # Raised when you attempt to create an attribute which has a name that
      # conflicts with reserved names (generally, defined method names). If you
      # see this error, you should change the attribute name in the model. If
      # the database uses this name, you can take advantage of the
      # +:database_attribute_name+ option in
      # {Aws::Record::Attributes::ClassMethods#attr #attr}
      class ReservedName < RuntimeError; end

      # Raised when you attempt a table migration and your model class is
      # invalid.
      class InvalidModel < RuntimeError; end

      # Raised when you attempt update/delete operations on a table that does
      # not exist.
      class TableDoesNotExist < RuntimeError; end

      class MissingRequiredConfiguration < RuntimeError; end

      # Raised when you attempt to combine your own condition expression with
      # the auto-generated condition expression from a "safe put" from saving
      # a new item in a transactional write operation. The path forward until
      # this case is supported is to use a plain "put" call, and to include
      # the key existance check yourself in your condition expression if you
      # wish to do so.
      class TransactionalSaveConditionCollision < RuntimeError; end

      # Raised when you attempt to combine your own update expression with
      # the update expression auto-generated from updates to an item's
      # attributes. The path forward until this case is supported is to
      # perform attribute updates yourself in your update expression if you
      # wish to do so.
      class UpdateExpressionCollision < RuntimeError; end
    end
  end
end
