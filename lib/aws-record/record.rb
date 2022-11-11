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

  # +Aws::Record+ is the module you include in your model classes in order to
  # decorate them with the Amazon DynamoDB integration methods provided by this
  # library. Methods you can use are shown below, in sub-modules organized by
  # functionality.
  # === Inheritance Support
  # This support allows models to be extended. If a user extends an +Aws::Record+
  # model class, the following be inherited:
  # * {#set_table_name set_table_name}
  # * {#initialize Attributes and keys}
  # * Mutation Tracking:
  #   * {#enable_mutation_tracking enable_mutation_tracking}
  #   * {#disable_mutation_tracking disable_mutation_tracking}
  # * {#local_secondary_indexes local_secondary_indexes}
  # * {#global_secondary_indexes global_secondary_indexes}
  # * {ClientConfiguration#configure_client configure_client}
  # See example below to see the feature in action.
  # @example A class definition using +Aws::Record+
  #   class MyModel
  #     include Aws::Record
  #     string_attr     :uuid,    hash_key: true
  #     integer_attr    :post_id, range_key: true
  #     boolean_attr    :is_active
  #     datetime_attr   :created_at
  #     string_set_attr :tags
  #     map_attr        :metadata
  #   end
  # @example Inheritance between models
  #   class Animal
  #     include Aws::Record
  #     string_attr :name, hash_key: true
  #     integer_attr :age
  #   end
  #
  #   class Dog < Animal
  #     include Aws::Record
  #     boolean_attr :family_friendly
  #   end
  #
  #   dog = Dog.find(name: 'Sunflower')
  #   dog.age = 3
  #   dog.family_friendly = true
  module Record
    # @!parse extend RecordClassMethods
    # @!parse include Attributes
    # @!parse extend Attributes::ClassMethods
    # @!parse include ItemOperations
    # @!parse extend ItemOperations::ItemOperationsClassMethods
    # @!parse include Query
    # @!parse extend Query::QueryClassMethods
    # @!parse include SecondaryIndexes
    # @!parse extend SecondaryIndexes::SecondaryIndexesClassMethods
    # @!parse include DirtyTracking
    # @!parse extend DirtyTracking::DirtyTrackingClassMethods

    # Usage of {Aws::Record} requires only that you include this module. This
    # method will then pull in the other default modules.
    #
    # @example
    #   class MyTable
    #     include Aws::Record
    #     # Attribute definitions go here...
    #   end
    def self.included(sub_class)
      sub_class.send(:extend, ClientConfiguration)
      sub_class.send(:extend, RecordClassMethods)
      sub_class.send(:include, Attributes)
      sub_class.send(:include, ItemOperations)
      sub_class.send(:include, DirtyTracking)
      sub_class.send(:include, Query)
      sub_class.send(:include, SecondaryIndexes)
      if sub_class.superclass.include?(Aws::Record)
        superclass_track_mutations = sub_class.superclass.instance_variable_get("@track_mutations")
        sub_class.instance_variable_set("@track_mutations", superclass_track_mutations)
      end
    end

    private
    def dynamodb_client
      self.class.dynamodb_client
    end

    module RecordClassMethods

      # Returns the Amazon DynamoDB table name for this model class.
      #
      # By default, this will simply be the name of the class. However, you can
      # also define a custom table name at the class level to be anything that
      # you want.
      #
      # *Note*: Can be inherited to child models if defined in parent model.
      # See {set_table_name} for more details.
      # @example
      #   class MyTable
      #     include Aws::Record
      #   end
      #
      #   class MyOtherTable
      #     include Aws::Record
      #     set_table_name "test_MyTable"
      #   end
      #
      #   MyTable.table_name      # => "MyTable"
      #   MyOtherTable.table_name # => "test_MyTable"
      def table_name
        @table_name ||= begin
          if self.superclass.include?(Aws::Record) &&
              default_table_name(self.superclass) != self.superclass.table_name
            self.superclass.instance_variable_get('@table_name')
          else
            default_table_name(self)
          end
        end
      end

      # Allows you to set a custom Amazon DynamoDB table name for this model
      # class.
      # === Inheritance Support
      # +table_name+ can be inherited to child models if defined in parent model.
      #
      # The parent model will need to have +set_table_name+ defined in their model
      # for the child model to inherit the +table_name+.
      # If no +set_table_name+ is defined, the parent and child models will have separate
      # table names based on their class name.
      #
      # If both parent and child models have defined +set_table_name+ in their model,
      # the child model will override the +table_name+ with theirs.
      # @example Setting custom table name for model class
      #   class MyTable
      #     include Aws::Record
      #     set_table_name "prod_MyTable"
      #   end
      #
      #   class MyOtherTable
      #     include Aws::Record
      #     set_table_name "test_MyTable"
      #   end
      #
      #   MyTable.table_name      # => "prod_MyTable"
      #   MyOtherTable.table_name # => "test_MyTable"
      # @example Child model inherits table name from Parent model
      #   class Animal
      #     include Aws::Record
      #     set_table_name "AnimalTable"
      #   end
      #
      #   class Dog < Animal
      #     include Aws::Record
      #   end
      #
      #   Dog.table_name      # => "AnimalTable"
      # @example Child model overrides table name from Parent model
      #   class Animal
      #     include Aws::Record
      #     set_table_name "AnimalTable"
      #   end
      #
      #   class Dog < Animal
      #     include Aws::Record
      #     set_table_name "DogTable"
      #   end
      #
      #   Dog.table_name      # => "DogTable"
      def set_table_name(name)
        @table_name = name
      end

      # Fetches the table's provisioned throughput from the associated Amazon
      # DynamoDB table.
      #
      # @return [Hash] a hash containing the +:read_capacity_units+ and
      #   +:write_capacity_units+ of your remote table.
      # @raise [Aws::Record::Errors::TableDoesNotExist] if the table name does
      #   not exist in DynamoDB.
      def provisioned_throughput
        begin
          resp = dynamodb_client.describe_table(table_name: table_name)
          throughput = resp.table.provisioned_throughput
          return {
            read_capacity_units: throughput.read_capacity_units,
            write_capacity_units: throughput.write_capacity_units
          }
        rescue DynamoDB::Errors::ResourceNotFoundException
          raise Record::Errors::TableDoesNotExist
        end
      end

      # Checks if the model's table name exists in Amazon DynamoDB.
      #
      # @return [Boolean] true if the table does exist, false if it does not.
      def table_exists?
        begin
          resp = dynamodb_client.describe_table(table_name: table_name)
          if resp.table.table_status == "ACTIVE"
            true
          else
            false
          end
        rescue DynamoDB::Errors::ResourceNotFoundException
          false
        end
      end

      # Turns off mutation tracking for all attributes in the model.
      #
      # *Note*: Can be inherited to child models if defined in parent model.
      def disable_mutation_tracking
        @track_mutations = false
      end

      # Turns on mutation tracking for all attributes in the model. Note that
      # mutation tracking is on by default, so you generally would not need to
      # call this. It is provided in case there is a need to dynamically turn
      # this feature on and off, though that would be generally discouraged and
      # could cause inaccurate mutation tracking at runtime.
      #
      # *Note*: Can be inherited to child models if defined in parent model.
      def enable_mutation_tracking
        @track_mutations = true
      end

      # @return [Boolean] true if mutation tracking is enabled at the model
      # level, false otherwise.
      def mutation_tracking_enabled?
        if defined?(@track_mutations)
          @track_mutations
        else
          @track_mutations = true
        end
      end

      def model_valid?
        if @keys.hash_key.nil?
          raise Errors::InvalidModel.new("Table models must include a hash key")
        end
      end

      private
      def default_table_name(klass)
        return unless klass.name
        klass.name.split("::").join("_")
      end

    end
  end
end
