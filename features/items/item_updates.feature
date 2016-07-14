# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
@dynamodb @item @update
Feature: Amazon DynamoDB Item Updates
  This feature tests functionality designed to prefer update calls to put calls
  when possible, in order to avoid accidental overwrite of unmodeled fields. For
  example, this kind of feature is useful in single-table inheritance scenarios,
  where the same table may serve multiple models. It also provides safety checks
  against overwriting existing items, if unintended. To run these tests, you
  will need to have valid AWS credentials that are accessible with the AWS SDK
  for Ruby's standard credential provider chain. In practice, this means a
  shared credential file or environment variables with your credentials. These
  tests may have some AWS costs associated with running them since AWS resources
  are created and destroyed within these tests.

  Background:
    Given a DynamoDB table named 'shared' with data:
      """
      [
        { "attribute_name": "hk", "attribute_type": "S", "key_type": "HASH" },
        { "attribute_name": "rk", "attribute_type": "S", "key_type": "RANGE" }
      ]
      """
    And an item exists in the DynamoDB table with item data:
      """
      {
        "hk": "sample",
        "rk": "sample",
        "x": "x",
        "y": "y",
        "z": "z"
      }
      """

  Scenario: Overwriting an Existing Object With #put_item Fails Without :force
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "hk", "hash_key": true },
        { "method": "string_attr", "name": "rk", "range_key": true },
        { "method": "string_attr", "name": "x" },
        { "method": "string_attr", "name": "y" },
        { "method": "string_attr", "name": "z" }
      ]
      """
    When we create a new instance of the model with attribute value pairs:
      """
      [
        ["hk", "sample"],
        ["rk", "sample"],
        ["x", "foo"]
      ]
      """
    Then calling save should raise a conditional save exception
    And we call the 'find' class method with parameter data:
      """
      {
        "hk": "sample",
        "rk": "sample"
      }
      """
    And we should receive an aws-record item with attribute data:
      """
      {
        "hk": "sample",
        "rk": "sample",
        "x": "x",
        "y": "y",
        "z": "z"
      }
      """
  Scenario: Updating an Object Does Not Clobber Unmodeled Attributes
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "hk", "hash_key": true },
        { "method": "string_attr", "name": "rk", "range_key": true },
        { "method": "string_attr", "name": "x" }
      ]
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "hk": "sample",
        "rk": "sample"
      }
      """
    And we set the item attribute "x" to be "bar"
    And we save the model instance
    Then an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "hk", "hash_key": true },
        { "method": "string_attr", "name": "rk", "range_key": true },
        { "method": "string_attr", "name": "x" },
        { "method": "string_attr", "name": "y" },
        { "method": "string_attr", "name": "z" }
      ]
      """
    And we call the 'find' class method with parameter data:
      """
      {
        "hk": "sample",
        "rk": "sample"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "hk": "sample",
        "rk": "sample",
        "x": "bar",
        "y": "y",
        "z": "z"
      }
      """
    
  Scenario: Updating an Object Does Not Clobber Non-Dirty Attributes
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "hk", "hash_key": true },
        { "method": "string_attr", "name": "rk", "range_key": true },
        { "method": "string_attr", "name": "x" },
        { "method": "string_attr", "name": "y" },
        { "method": "string_attr", "name": "z" }
      ]
      """
    When we call the 'query' class method with parameter data:
      """
      {
        "key_conditions": {
          "hk": {
            "attribute_value_list": ["sample"],
            "comparison_operator": "EQ"
          }
        },
        "projection_expression": "hk, rk, x, y"
      }
      """
    And we should receive an aws-record collection with members:
      """
      [
        {
          "hk": "sample",
          "rk": "sample",
          "x": "x",
          "y": "y",
          "z": null
        }
      ]
      """
    And we take the first member of the result collection
    And we set the item attribute "y" to be "foo"
    And we save the model instance
    And we call the 'find' class method with parameter data:
      """
      {
        "hk": "sample",
        "rk": "sample"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "hk": "sample",
        "rk": "sample",
        "x": "x",
        "y": "foo",
        "z": "z"
      }
      """

  Scenario: Updating an Object with the Update Model Method
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "hk", "hash_key": true },
        { "method": "string_attr", "name": "rk", "range_key": true },
        { "method": "string_attr", "name": "x" },
        { "method": "string_attr", "name": "y" },
        { "method": "string_attr", "name": "z" }
      ]
      """
    When we call the 'update' class method with parameter data:
      """
      {
        "hk": "sample",
        "rk": "sample",
        "y": "foo",
        "z": "bar"
      }
      """
    And we call the 'find' class method with parameter data:
      """
      {
        "hk": "sample",
        "rk": "sample"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "hk": "sample",
        "rk": "sample",
        "x": "x",
        "y": "foo",
        "z": "bar"
      }
      """
