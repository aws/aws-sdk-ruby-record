# language: en

@dynamodb @batch
Feature: Amazon DynamoDB Batch
  This feature tests the ability to use the batch read and write item APIs via
  aws-record. To run these tests, you will need to have valid AWS credentials
  that are accessible with the AWS SDK for Ruby's standard credential provider
  chain. In practice, this means a shared credential file or environment
  variables with your credentials. These tests may have some AWS costs associated
  with running them since AWS resources are created and destroyed within
  these tests.

  Background:
    Given a Parent model with definition:
      """
      set_table_name('FoodTable')
      integer_attr :id, hash_key: true, database_attribute_name: 'Food ID'
      string_attr :dish, range_key: true
      boolean_attr :spicy
      """
    And a Parent model with TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(ParentTableModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB
    And a Child model with definition:
      """
        set_table_name('DessertTable')
        boolean_attr :gluten_free
      """
    And a Child model with TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(ChildTableModel)
        t.read_capacity_units(2)
        t.write_capacity_units(2)
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    Then eventually the table should exist in DynamoDB

  Scenario: Perform a batch set of writes and read
    When we make a batch write call with following Parent and Child model items:
      """
      [
        { "model": "Parent", "id": 1, "dish": "Papaya Salad", "spicy": true },
        { "model": "Parent", "id": 2, "dish": "Hamburger", "spicy": false },
        { "model": "Child", "id": 1, "dish": "Apple Pie", "spicy": false, "gluten_free": false }
      ]
      """
    And we make a batch read call for the following Parent and Child model item keys:
      """
      [
        { "model": "Parent", "id": 1, "dish": "Papaya Salad" },
        { "model": "Parent", "id": 2, "dish": "Hamburger" },
        { "model": "Child", "id": 1, "dish": "Apple Pie" }
      ]
      """
    Then we expect the batch read result to include the following items:
      """
      [
        { "id": 1, "dish": "Papaya Salad", "spicy": true },
        { "id": 2, "dish": "Hamburger", "spicy": false },
        { "id": 1, "dish": "Apple Pie", "spicy": false, "gluten_free": false }
      ]
      """