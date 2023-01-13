# language: en

@dynamodb @table
Feature: Amazon DynamoDB Tables
  This feature tests the integration of model classes that include the
  Aws::Record module with the Aws::Record::TableMigration class, which helps to
  run table change operations on DynamoDB. To run these tests, you will need to
  have valid AWS credentials that are accessible with the AWS SDK for Ruby's
  standard credential provider chain. In practice, this means a shared
  credential file or environment variables with your credentials. These tests
  may have some AWS costs associated with running them since AWS resources are
  created and destroyed within these tests.

  Background:
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "count", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
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

  Scenario: Create a DynamoDB Table with aws-record
    Then eventually the table should exist in DynamoDB
    And calling 'table_exists?' on the model should return "true"

  Scenario: Delete a DynamoDB Table After Creation
    When eventually the table should exist in DynamoDB
    And we call 'delete!' on the migration
    Then eventually the table should not exist in DynamoDB
    And calling 'table_exists?' on the model should return "false"

  Scenario: Provide a Migration Waiter
    When we call 'wait_until_available' on the migration
    Then calling 'table_exists?' on the model should return "true"

  Scenario: Update a Table After Creation
    When we call 'wait_until_available' on the migration
    And calling "provisioned_throughput" on the model should return:
      """
      {
        "read_capacity_units": 1,
        "write_capacity_units": 1
      }
      """
    And we call 'update!' on the migration with parameters:
      """
      {
        "provisioned_throughput": {
          "read_capacity_units": 3,
          "write_capacity_units": 2
        }
      }
      """
    Then calling "provisioned_throughput" on the model should return:
      """
      {
        "read_capacity_units": 3,
        "write_capacity_units": 2
      }
      """
