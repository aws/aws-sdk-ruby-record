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
@dynamodb @search
Feature: Amazon DynamoDB Querying and Scanning
  This feature tests integration of the client #query and #scan methods with the
  Aws::Record abstraction.  To run these tests, you will need to have valid AWS
  credentials that are accessible with the AWS SDK for Ruby's standard
  credential provider chain. In practice, this means a shared credential file or
  environment variables with your credentials. These tests may have some AWS
  costs associated with running them since AWS resources are created and
  destroyed within these tests.

  Background:
    Given a DynamoDB table named 'example' with data:
      """
      [
        { "attribute_name": "id", "attribute_type": "S", "key_type": "HASH" },
        { "attribute_name": "count", "attribute_type": "N", "key_type": "RANGE" }
      ]
      """
    And an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "count", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
      """
    And an item exists in the DynamoDB table with item data:
      """
      {
        "id": "1",
        "count": 5,
        "content": "First item."
      }
      """
    And an item exists in the DynamoDB table with item data:
      """
      {
        "id": "1",
        "count": 10,
        "content": "Second item."
      }
      """
    And an item exists in the DynamoDB table with item data:
      """
      {
        "id": "1",
        "count": 15,
        "content": "Third item."
      }
      """
    And an item exists in the DynamoDB table with item data:
      """
      {
        "id": "2",
        "count": 10,
        "content": "Fourth item."
      }
      """

  Scenario: Run Query Directly From Aws::DynamoDB::Client#query
    When we call the 'query' class method with parameter data:
      """
      {
        "key_conditions": {
          "id": {
            "attribute_value_list": ["1"],
            "comparison_operator": "EQ"
          },
          "count": {
            "attribute_value_list": [7],
            "comparison_operator": "GT"
          }
        }
      }
      """
    Then we should receive an aws-record collection with members:
      """
      [
        {
          "id": "1",
          "count": 10,
          "body": "Second item."
        },
        {
          "id": "1",
          "count": 15,
          "body": "Third item."
        }
      ]
      """

  Scenario: Run Scan Directly From Aws::DynamoDB::Client#scan
    When we call the 'scan' class method
    Then we should receive an aws-record collection with members:
      """
      [
        {
          "id": "1",
          "count": 5,
          "body": "First item."
        },
        {
          "id": "1",
          "count": 10,
          "body": "Second item."
        },
        {
          "id": "1",
          "count": 15,
          "body": "Third item."
        },
        {
          "id": "2",
          "count": 10,
          "body": "Fourth item."
        }
      ]
      """

  @wip
  Scenario: Paginate Manually With Multiple Calls
    When we call the 'scan' class method with parameter data:
      """
      {
        "limit": 2
      }
      """
    Then we should receive an aws-record page with 2 values from members:
      """
      [
        {
          "id": "1",
          "count": 5,
          "body": "First item."
        },
        {
          "id": "1",
          "count": 10,
          "body": "Second item."
        },
        {
          "id": "1",
          "count": 15,
          "body": "Third item."
        },
        {
          "id": "2",
          "count": 10,
          "body": "Fourth item."
        }
      ]
      """
    When we call the 'scan' class method using the page's pagination token
    Then we should receive an aws-record page with 2 values from members:
      """
      [
        {
          "id": "1",
          "count": 5,
          "body": "First item."
        },
        {
          "id": "1",
          "count": 10,
          "body": "Second item."
        },
        {
          "id": "1",
          "count": 15,
          "body": "Third item."
        },
        {
          "id": "2",
          "count": 10,
          "body": "Fourth item."
        }
      ]
      """
