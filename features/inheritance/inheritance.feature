# language: en

@dynamodb @inheritance
Feature: Amazon DynamoDB Inheritance
  This feature tests inheritance between parent class and child classes. To run
  these tests, you will need to have valid AWS credentials that are accessible
  with the AWS SDK for Ruby's standard credential provider chain. In practice,
  this means a shared credential file or environment variables with your credentials.
  These tests may have some AWS costs associated with running them since AWS resources
  are created and destroyed within these tests.


  Background:
    Given a Parent model with definition:
      """
      set_table_name('Animal')
      integer_attr  :id,    hash_key: true
      string_attr :name, range_key: true
      string_attr :size
      list_attr :characteristics
      global_secondary_index(
        :gsi,
        hash_key:  :id,
        range_key: :size,
        projection: {
          projection_type: "ALL"
        }
      )
      """

  Scenario: Create a Table and be able to create Items from both Child model and Parent model
    Given a Child model with definition:
      """
      boolean_attr :family_friendly
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
    Then eventually the table should exist in DynamoDB
    And the table should have a global secondary index named "gsi"
    And we create a new instance of the Child model with attribute value pairs:
      """
      [
        ["id", 1],
        ["name", "Cheeseburger"],
        ["size", "Large"],
        ["characteristics", ["Friendly", "Curious", "Loves kisses"]],
        ["family_friendly", true]
      ]
      """
    And we save the model instance
    And we call the 'find' class method with parameter data:
      """
      {
        "id": 1,
        "name": "Cheeseburger"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "id": 1,
        "name": "Cheeseburger",
        "size": "Large",
        "characteristics": ["Friendly", "Curious", "Loves kisses"],
        "family_friendly": true
      }
      """
    And we create a new instance of the Parent model with attribute value pairs:
      """
      [
        ["id", 2],
        ["name", "Applejack"],
        ["size", "Medium"],
        ["characteristics", ["Aloof", "Dignified"]]
      ]
      """
    And we save the model instance
    And we call the 'find' class method with parameter data:
      """
      {
        "id": 2,
        "name": "Applejack"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "id": 2,
        "name": "Applejack",
        "size": "Medium",
        "characteristics": ["Aloof", "Dignified"]
      }
      """

  Scenario:  Create a Table based on the Child Model and be able to create an item
    Given a Child model with definition:
      """
      set_table_name('Cat')
      integer_attr  :toe_beans
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
    Then eventually the table should exist in DynamoDB
    And we create a new instance of the Child model with attribute value pairs:
      """
      [
        ["id", 1],
        ["name", "Donut"],
        ["size", "Chonk"],
        ["characteristics", ["Makes good bread", "Likes snacks"]],
        ["toe_beans", 9]
      ]
      """
    And we save the model instance
    And we call the 'find' class method with parameter data:
      """
      {
        "id": 1,
        "name": "Donut"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "id": 1,
        "name": "Donut",
        "size": "Chonk",
        "characteristics": ["Makes good bread", "Likes snacks"],
        "toe_beans": 9
      }
      """