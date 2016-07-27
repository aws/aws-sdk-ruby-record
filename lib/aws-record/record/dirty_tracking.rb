# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

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
        #@dirty_data.has_key?(name) || _mutated?(name)
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
        #if @mutation_copies.has_key?(name)
        #  @mutation_copies[name]
        #else
        #  attribute_dirty?(name) ? @dirty_data[name] : @data.raw_value(name)
        #end
        @data.attribute_was(name)
      end

      # Mark that an attribute is changing. This is useful in situations where it is necessary to track that the value of an 
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
        #return if attribute_dirty?(name)
        #current_value = @data.raw_value(name)
        #@dirty_data[name] = 
        #  begin
        #    _deep_copy(current_value)
        #  rescue TypeError
        #    current_value
        #  end
        @data.attribute_dirty!(name)
      end

      # Marks the changes as applied by clearing the current changes and making 
      # them accessible through +previous_changes+.
      #
      # # @example
      #  class Model
      #    include Aws::Record
      #    integer_attr :id, hash_key: true
      #    string_attr  :name
      #  end
      #
      #  model.name   # => 'Alex'
      #  model.name = 'Nick'
      #  model.dirty? # => true
      #
      #  model.clean!
      #  model.dirty? # false
      #
      def clean!
        #@dirty_data.clear
        #self.class.attributes.attributes.each do |name, attribute|
        #  if self.class.track_mutations?(name)
        #    if @data.raw_value(name)
        #      @mutation_copies[name] = _deep_copy(@data.raw_value(name))
        #    end
        #  end
        #end
        @data.clean!
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
        #ret = @dirty_data.keys.dup
        #@mutation_copies.each do |key, value|
        #  if @data.raw_value(key) != value
        #    ret << key unless ret.include?(key)
        #  end
        #end
        #ret
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
        #return true if @dirty_data.size > 0
        #@mutation_copies.any? do |name, value|
        #  @mutation_copies[name] != @data.raw_value(name)
        #end
        @data.dirty?
      end

      # Fetches attributes for this instance of an item from Amazon DynamoDB 
      # using its primary key and the +find(*)+ class method.
      #
      # @raise [Aws::Record::Errors::NotFound] if no record exists in the 
      #  database matching the primary key of the item instance.
      # 
      # @return [self] Returns the item instance.
      def reload!
        primary_key = self.class.keys.values.inject({}) do |memo, key| 
          memo[key] = send(key)
          memo 
        end

        record = self.class.find(primary_key)

        unless record.nil?
          @data = record.instance_variable_get("@data")
        else
          raise Errors::NotFound.new("No record found")
        end

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
        #return unless attribute_dirty?(name)
        #if @mutation_copies.has_key?(name)
        #  @data.set_attribute(name, @mutation_copies[name])
        #  @dirty_data.delete(name) if @dirty_data.has_key?(name)
        #else
        #  @data.set_attribute(name, @dirty_data.delete(name))
        #end
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

      # @private
      #
      # @override save(*)
      def save(*)
        super.tap { clean! }
      end

      module DirtyTrackingClassMethods

        private

        # @private
        #
        # @override build_item_from_resp(*)
        def build_item_from_resp(*)
          super.tap { |item| item.clean! }
        end

        # @private
        #
        # @override define_attr_methods(*)
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
