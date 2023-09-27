# frozen_string_literal: true

module Aws
  module Record
    module DirtyTracking
      def self.included(sub_class)
        sub_class.extend(DirtyTrackingClassMethods)
      end

      # Returns +true+ if the specified attribute has any dirty changes, +false+ otherwise.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.name_dirty? # => false
      #  model.name     # => 'Alex'
      #  model.name = 'Nick'
      #  model.name_dirty? # => true
      #
      # @param [String, Symbol] name The name of the attribute to to check for dirty changes.
      # @return [Boolean] +true+ if the specified attribute has any dirty changes, +false+ otherwise.
      def attribute_dirty?(name)
        @data.attribute_dirty?(name)
      end

      # Returns the original value of the specified attribute.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id,   hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.name         # => 'Alex'
      #  model.name = 'Nick'
      #  model.name_was     # => 'Alex'
      #
      # @param [String, Symbol] name The name of the attribute to retrieve the original value of.
      # @return [Object] The original value of the specified attribute.
      def attribute_was(name)
        @data.attribute_was(name)
      end

      # Mark that an attribute is changing. This is useful in situations
      # where it is necessary to track that the value of an
      # attribute is changing in-place.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id,   hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.name        # => 'Alex'
      #  model.name_dirty? # => false
      #  model.name_was    # => 'Alex'
      #
      #  model.name << 'i'
      #  model.name        # => 'Alexi'
      #
      #  # The change was made in place. Since the String instance representing
      #  # the value of name is the same as it was originally, the change is not
      #  # detected.
      #  model.name_dirty? # => false
      #  model.name_was    # => 'Alexi'
      #
      #  model.name_dirty!
      #  model.name_dirty? # => true
      #  model.name_was    # => 'Alexi'
      #
      #  model.name << 's'
      #  model.name        # => 'Alexis'
      #  model.name_dirty? # => true
      #  model.name_was    # => 'Alexi'
      #
      # @param [String, Symbol] name The name of the attribute to mark as
      #  changing.
      def attribute_dirty!(name)
        @data.attribute_dirty!(name)
      end

      # Returns an array with the name of the attributes with dirty changes.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.dirty # => []
      #  model.name  # => 'Alex'
      #  model.name = 'Nick'
      #  model.dirty # => ['name']
      #
      # @return [Array] The names of attributes with dirty changes.
      def dirty
        @data.dirty
      end

      # Returns +true+ if any attributes have dirty changes, +false+ otherwise.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.dirty? # => false
      #  model.name   # => 'Alex'
      #  model.name = 'Nick'
      #  model.dirty? # => true
      #
      # @return [Boolean] +true+ if any attributes have dirty changes, +false+
      #  otherwise.
      def dirty?
        @data.dirty?
      end

      # Returns +true+ if the model is not new and has not been deleted, +false+ otherwise.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model = Model.new
      #  model.persisted? # => false
      #  model.save
      #  model.persisted? # => true
      #  model.delete!
      #  model.persisted? # => false
      #
      # @return [Boolean] +true+ if the model is not new and has not been deleted, +false+
      #  otherwise.
      def persisted?
        @data.persisted?
      end

      # Returns +true+ if the model is newly initialized, +false+ otherwise.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model = Model.new
      #  model.new_record? # => true
      #  model.save
      #  model.new_record? # => false
      #
      # @return [Boolean] +true+ if the model is newly initialized, +false+
      #  otherwise.
      def new_record?
        @data.new_record?
      end

      # Returns +true+ if the model has been destroyed, +false+ otherwise.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model = Model.new
      #  model.destroyed? # => false
      #  model.save
      #  model.destroyed? # => false
      #  model.delete!
      #  model.destroyed? # => true
      #
      # @return [Boolean] +true+ if the model has been destroyed, +false+
      #  otherwise.
      def destroyed?
        @data.destroyed?
      end

      # Fetches attributes for this instance of an item from Amazon DynamoDB
      # using its primary key and the +find(*)+ class method.
      #
      # @raise [Aws::Record::Errors::NotFound] if no record exists in the
      #  database matching the primary key of the item instance.

      # @return [self] Returns the item instance.
      def reload!
        primary_key = self.class.keys.values.each_with_object({}) do |key, memo|
          memo[key] = send(key)
          memo
        end

        record = self.class.find(primary_key)

        raise Errors::NotFound, 'No record found' unless record.present?

        @data = record.instance_variable_get('@data')

        clean!

        self
      end

      # Restores the attribute specified to its original value.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.name # => 'Alex'
      #  model.name = 'Nick'
      #  model.rollback_attribute!(:name)
      #  model.name # => 'Alex'
      #
      # @param [String, Symbol] name The name of the attribute to restore
      def rollback_attribute!(name)
        @data.rollback_attribute!(name)
      end

      # Restores all attributes to their original values.
      #
      # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.name # => 'Alex'
      #  model.name = 'Nick'
      #  model.rollback!
      #  model.name # => 'Alex'
      #
      # @param [Array, String, Symbol] names The names of attributes to restore.
      def rollback!(names = dirty)
        Array(names).each { |name| rollback_attribute!(name) }
      end

      # @api private
      def clean!
        @data.clean!
      end

      # @private
      def save(*)
        super.tap { clean! }
      end

      module DirtyTrackingClassMethods
        private

        # @private
        def build_item_from_resp(*)
          super.tap(&:clean!)
        end

        # @private
        def _define_attr_methods(name)
          super.tap do
            define_method("#{name}_dirty?") do
              attribute_dirty?(name)
            end

            define_method("#{name}_dirty!") do
              attribute_dirty!(name)
            end

            define_method("#{name}_was") do
              attribute_was(name)
            end

            define_method("rollback_#{name}!") do
              rollback_attribute!(name)
            end
          end
        end
      end
    end
  end
end
