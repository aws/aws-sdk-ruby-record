# language: en

@dynamodb @table @table_config
Feature: Aws::Record::TableConfig

  Scenario: Create a New Table With TableConfig
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  Scenario: Update an Existing Table With TableConfig
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.client_options(region: "us-east-1")
      end
      """
    When we create a table migration for the model
    And we call 'create!' with parameters:
      """
      {
        "provisioned_throughput": {
          "read_capacity_units": 1,
          "write_capacity_units": 1
        }
      }
      """
    Then eventually the table should exist in DynamoDB
    And the TableConfig should not be compatible with the remote table
    When we migrate the TableConfig
    Then the TableConfig should be compatible with the remote table

  Scenario: Create a New Table With Global Secondary Indexes
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      string_attr  :gsi_range
      global_secondary_index(
        :gsi,
        hash_key:  :id,
        range_key: :gsi_range,
        projection: {
          projection_type: "ALL"
        }
      )
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.global_secondary_index(:gsi) do |i|
          i.read_capacity_units(1)
          i.write_capacity_units(1)
        end
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @slow
  Scenario: Update a Table to Add Global Secondary Indexes
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      string_attr  :gsi_range
      """
    When we create a table migration for the model
    And we call 'create!' with parameters:
      """
      {
        "provisioned_throughput": {
          "read_capacity_units": 1,
          "write_capacity_units": 1
        }
      }
      """
    Then eventually the table should exist in DynamoDB
    Given we add a global secondary index to the model with definition:
      """
      [
        :gsi,
        {
          hash_key:  :id,
          range_key: :gsi_range,
          projection: {
            projection_type: "ALL"
          }
        }
      ]
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.global_secondary_index(:gsi) do |i|
          i.read_capacity_units(1)
          i.write_capacity_units(1)
        end
        t.client_options(region: "us-east-1")
      end
      """
    Then the TableConfig should not be compatible with the remote table
    When we migrate the TableConfig
    Then the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ttl
  Scenario: Create a New Table With TTL
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      epoch_time_attr :ttl
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.ttl_attribute(:ttl)
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ttl
  Scenario: Update an Existing Table With TTL
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      epoch_time_attr :ttl
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.ttl_attribute(:ttl)
        t.client_options(region: "us-east-1")
      end
      """
    When we create a table migration for the model
    And we call 'create!' with parameters:
      """
      {
        "provisioned_throughput": {
          "read_capacity_units": 2,
          "write_capacity_units": 2
        }
      }
      """
    Then eventually the table should exist in DynamoDB
    And the TableConfig should not be compatible with the remote table
    When we migrate the TableConfig
    Then the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ppr
  Scenario: Create a New Table With PPR Billing
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.billing_mode("PAY_PER_REQUEST")
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ppr @veryslow
  Scenario: Transition from PPR Billing to Provisioned
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.billing_mode("PAY_PER_REQUEST")
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB
    And the TableConfig should be an exact match with the remote table
    Given a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.client_options(region: "us-east-1")
      end
      """
    Then the TableConfig should not be compatible with the remote table
    When we migrate the TableConfig
    Then the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ppr @veryslow
  Scenario: Transition from Provisioned Billing to PPR
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB
    And the TableConfig should be an exact match with the remote table
    Given a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.billing_mode("PAY_PER_REQUEST")
        t.client_options(region: "us-east-1")
      end
      """
    Then the TableConfig should not be compatible with the remote table
    When we migrate the TableConfig
    Then the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ppr @slow
  Scenario: Create a New Table With Global Secondary Indexes and PPR
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      string_attr  :gsi_range
      global_secondary_index(
        :gsi,
        hash_key:  :id,
        range_key: :gsi_range,
        projection: {
          projection_type: "ALL"
        }
      )
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.billing_mode("PAY_PER_REQUEST")
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  @ppr @slow
  Scenario: Update a PPR Table to Add Global Secondary Indexes
    Given an aws-record model with definition:
      """
      string_attr  :id,    hash_key: true
      integer_attr :count, range_key: true
      string_attr  :gsi_range
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.billing_mode("PAY_PER_REQUEST")
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table
    Given we add a global secondary index to the model with definition:
      """
      [
        :gsi,
        {
          hash_key:  :id,
          range_key: :gsi_range,
          projection: {
            projection_type: "ALL"
          }
        }
      ]
      """
    Then the TableConfig should not be compatible with the remote table
    When we migrate the TableConfig
    Then the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table
