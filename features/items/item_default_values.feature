# language: en
@dynamodb @item @default_values
Feature: Aws::Record Attribute Default Values

  Scenario: Write From Default Values
    Given an aws-record model with definition:
      """
      string_attr :id, hash_key: true
      map_attr :map, default_value: {}
      """
    And a TableConfig of:
      """
      Aws::Record::TableConfig.define do |t|
        t.model_class(TableConfigTestModel)
        t.read_capacity_units(1)
        t.write_capacity_units(1)
        t.client_options(region: "us-east-1")
      end
      """
    When we migrate the TableConfig
    And eventually the table should exist in DynamoDB
    And we create a new instance of the model with attribute value pairs:
      """
      [
        ["id", "1"]
      ]
      """
    And we apply the following keys and values to map attribute "map":
      """
      { "a" => "1" }
      """
    And we save the model instance
    And we create a new instance of the model with attribute value pairs:
      """
      [
        ["id", "2"]
      ]
      """
    And we apply the following keys and values to map attribute "map":
      """
      { "b" => "2" }
      """
    And we save the model instance
    When we call the 'find' class method with parameter data:
      """
      {
        "id": "1"
      }
      """
    Then the attribute "map" on the item should match:
      """
      { "a" => "1" }
      """
      When we call the 'find' class method with parameter data:
      """
      {
        "id": "2"
      }
      """
    Then the attribute "map" on the item should match:
      """
      { "b" => "2" }
      """
