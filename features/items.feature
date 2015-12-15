# language: en
@item
Feature: DynamoDB Items
  This feature tests the integration of model classes that include the
  Aws::Record module with a DynamoDB backend. To run these tests, you will need
  to have valid AWS credentials that are accessible with the AWS SDK for Ruby's
  standard credential provider chain. In practice, this means a shared
  credential file or environment variables with your credentials. These tests
  may have some AWS costs associated with running them since AWS resources are
  created and destroyed within these tests.

  Background:
    Given a DynamoDB table named 'example' with data:
      """
      [
        { "attribute_name": "id", "attribute_type": "S", "key_type": "HASH" },
        { "attribute_name": "count", "attribute_type": "N", "key_type": "RANGE" }
      ]
      """
    And an aws-record model for this table with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "count", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
      """

  Scenario: Write an Item with aws-record
    When we create a new instance of the model with attribute value pairs:
      """
      [
        ["id", 1],
        ["count", 1],
        ["body", "Hello!"]
      ]
      """
    And we save the model instance
    Then the DynamoDB table should have an object with key values:
      """
      [
        ["id", "1"],
        ["count", 1]
      ]
      """
