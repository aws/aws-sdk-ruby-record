# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# language: en
@dynamodb @table @table_config
Feature: Aws::Record::TableConfig

  Scenario: Create a New Table With TableConfig
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "count", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
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
    Then calling 'table_exists?' on the model should return "true"
    And the TableConfig should be compatible with the remote table
    And the TableConfig should be an exact match with the remote table

  Scenario: Update an Existing Table With TableConfig
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "count", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
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
