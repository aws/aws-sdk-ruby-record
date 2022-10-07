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

# language: en
@dynamodb @item
Feature: Amazon DynamoDB Items
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
        { "attribute_name": "rk", "attribute_type": "N", "key_type": "RANGE" }
      ]
      """
    And an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "rk", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
      """

  Scenario: Write an Item with aws-record
    When we create a new instance of the model with attribute value pairs:
      """
      [
        ["id", 1],
        ["rk", 1],
        ["body", "Hello!"]
      ]
      """
    And we save the model instance
    Then the DynamoDB table should have an object with key values:
      """
      [
        ["id", "1"],
        ["rk", 1]
      ]
      """

  Scenario: Read an Item from Amazon DynamoDB with aws-record
    Given an item exists in the DynamoDB table with item data:
      """
      {
        "id": "2",
        "rk": 10,
        "content": "Aliased column names!"
      }
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "id": "2",
        "rk": 10
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "id": "2",
        "rk": 10,
        "body": "Aliased column names!"
      }
      """

  Scenario: Delete an Item from Amazon DynamoDB with aws-record
    Given an item exists in the DynamoDB table with item data:
      """
      {
        "id": "3",
        "rk": 5,
        "content": "Body content."
      }
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "id": "3",
        "rk": 5
      }
      """
    And we call 'delete!' on the aws-record item instance
    Then the DynamoDB table should not have an object with key values:
      """
      [
        ["id", "3"],
        ["rk", 5]
      ]
      """

  Scenario: Update an Item from Amazon DynamoDB with aws-record
    Given an item exists in the DynamoDB table with item data:
      """
      {
        "id": "4",
        "rk": 5,
        "content": "Body content."
      }
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "id": "4",
        "rk": 5
      }
      """
    And we call 'update' on the aws-record item instance with parameter data:
      """
      {
        "body": "Updated Body Content."
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "id": "4",
        "rk": 5,
        "body": "Updated Body Content."
      }
      """

