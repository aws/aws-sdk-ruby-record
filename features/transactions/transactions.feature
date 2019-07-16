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

  @transact_find @global_transact_find
  Scenario: Get two items in a transaction (global)
    When we make a global transact_find call with parameters:
      """
      {
        transact_items: [
          TableConfigTestModel.tfind_opts(key: { uuid: "a1"}),
          TableConfigTestModel.tfind_opts(
            key: { uuid: "b2" },
            projection_expression: "#H, body",
            expression_attribute_names: {
              "#H" => "uuid"
            }
          ),
        ],
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

  @transact_find @global_transact_find
  Scenario: Get two items in a transaction plus one missing (global)
    When we make a global transact_find call with parameters:
      """
      {
        transact_items: [
          TableConfigTestModel.tfind_opts(key: {uuid: "a1"}),
          TableConfigTestModel.tfind_opts(key: {uuid: "nope"}),
          TableConfigTestModel.tfind_opts(key: {uuid: "b2"}),
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

  @transact_find @class_transact_find
  Scenario: Get two items in a transaction plus one missing (class)
    When we run the following transactional find:
      """
      TableConfigTestModel.transact_find(
        transact_items: [
          {key: {uuid: "a1"}},
          {key: {uuid: "nope"}},
          {key: {uuid: "b2"}},
        ]
      )
      """
    Then we expect a transact_find result that includes the following items:
      """
      [
        { uuid: "a1", body: "First item!", field: "Foo" },
        nil,
        { uuid: "b2", body: "Lorem ipsum.", field: "Bar" },
      ]
      """

  @transact_write @global_transact_write
  Scenario: Perform a transactional update (global)
    When we run the following code:
      """
      item1 = TableConfigTestModel.find(uuid: "a1")
      item1.body = "Updated a1!"
      item2 = TableConfigTestModel.find(uuid: "b2")
      item3 = TableConfigTestModel.new(uuid: "c3", body: "New item!")
      Aws::Record::Transactions.transact_write(
        transact_items: [
          { save: item1 },
          { save: item3 },
          { delete: item2 }
        ]
      )
      """
    Then the DynamoDB table should not have an object with key values:
      """
      [
        ["uuid", "b2"]
      ]
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "uuid": "a1"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "uuid": "a1",
        "body": "Updated a1!",
        "field": "Foo"
      }
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "uuid": "c3"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "uuid": "c3",
        "body": "New item!"
      }
      """

  @transact_write @global_transact_write
  Scenario: Perform a transactional set of puts and updates (global)
    When we run the following code:
      """
      item1 = TableConfigTestModel.new(uuid: "a1", body: "Replaced!")
      item2 = TableConfigTestModel.find(uuid: "b2")
      item2.body = "Updated b2!"
      item3 = TableConfigTestModel.new(uuid: "c3", body: "New item!")
      Aws::Record::Transactions.transact_write(
        transact_items: [
          { put: item1 },
          { put: item3 },
          { update: item2 }
        ]
      )
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "uuid": "a1"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "uuid": "a1",
        "body": "Replaced!"
      }
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "uuid": "b2"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "uuid": "b2",
        "body": "Updated b2!",
        "field": "Bar"
      }
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "uuid": "c3"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "uuid": "c3",
        "body": "New item!"
      }
      """

  @transact_write @global_transact_write
  Scenario: Perform a transactional update with check (global)
    When we run the following code:
      """
      item1 = TableConfigTestModel.find(uuid: "a1")
      item1.body = "Passing the check!"
      check_exp = TableConfigTestModel.transact_check_expression(
        key: { uuid: "b2" },
        condition_expression: "size(#T) <= :v",
        expression_attribute_names: {
          "#T" => "body"
        },
        expression_attribute_values: {
          ":v" => 1024
        }
      )
      Aws::Record::Transactions.transact_write(
        transact_items: [
          { save: item1 },
          { check: check_exp }
        ]
      )
      """
    When we call the 'find' class method with parameter data:
      """
      {
        "uuid": "a1"
      }
      """
    Then we should receive an aws-record item with attribute data:
      """
      {
        "uuid": "a1",
        "body": "Passing the check!",
        "field": "Foo"
      }
      """

  @transact_write @global_transact_write
  Scenario: Perform a transactional update in error (global)
    When we run the following code:
      """
      item1 = TableConfigTestModel.new(uuid: "a1", body: "Replaced!")
      item2 = TableConfigTestModel.new(uuid: "b2", body: "Sneaky replacement!")
      item3 = TableConfigTestModel.new(uuid: "c3", body: "New item!")
      Aws::Record::Transactions.transact_write(
        transact_items: [
          { save: item1 },
          { save: item2 },
          { save: item3 }
        ]
      )
      """
    Then we expect the code to raise an 'Aws::DynamoDB::Errors::TransactionCanceledException' exception
