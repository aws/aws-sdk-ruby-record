# Copyright 2015-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
@dynamodb @transactions
Feature: Amazon DynamoDB Transactions
  This feature tests the ability to use the transactional get and write item
  APIs via aws-record. To run these tests, you will need to have valid AWS
  credentials that are accessible with the AWS SDK for Ruby's standard
  credential provider chain. In practice, this means a shared credential file
  or environment variables with your credentials. These tests may have some AWS
  costs associated with running them since AWS resources are created and
  destroyed within these tests.

  Background:
    Given an aws-record model with definition:
      """
      string_attr :uuid, hash_key: true
      string_attr :body
      string_attr :field
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
    Given an item exists in the DynamoDB table with item data:
      """
      {
        "uuid": "a1",
        "body": "First item!",
        "field": "Foo"
      }
      """
    And an item exists in the DynamoDB table with item data:
      """
      {
        "uuid": "b2",
        "body": "Lorem ipsum.",
        "field": "Bar"
      }
      """

  Scenario: Get two items in a transaction
    When we make a transact_find call with parameters:
      """
      {
        get_item: [
          { model: TableConfigTestModel, key: { uuid: "a1" } },
          {
            model: TableConfigTestModel,
            key: { uuid: "b2" },
            projection_expression: "body"
          },
        ]
        return_consumed_capacity: "NONE"
      }
      """
    Then we expect a transact_find result that includes the following items:
      """
      [
        { uuid: "a1", body: "First item!", field: "Foo" },
        { uuid: "b2", body: "Lorem ipsum." },
      ]
      """

  Scenario: Get two items in a transaction plus one missing
    When we make a transact_find call with parameters:
      """
      {
        get_item: [
          { model: TableConfigTestModel, key: { uuid: "a1" } },
          { model: TableConfigTestModel, key: { uuid: "nope" } },
          { model: TableConfigTestModel, key: { uuid: "b2" } },
        ]
      }
      """
    Then we expect a transact_find result that includes the following items:
      """
      [
        { uuid: "a1", body: "First item!", field: "Foo" },
        nil,
        { uuid: "b2", body: "Lorem ipsum.", field: "Bar" },
      ]
      """
