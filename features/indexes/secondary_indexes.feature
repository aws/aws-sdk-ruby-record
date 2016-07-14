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
@dynamodb @table @secondary_indexes
Feature: Amazon DynamoDB Secondary Indexes
  This feature tests the integration of model classes which define global
  secondary indexes and/or local secondary indexes in DynamoDB. Indexes are
  defined in your Aws::Record model, and are applied with the
  Aws::Record::TableMigration class. To run these tests, you will need to
  have valid AWS credentials that are accessible with the AWS SDK for Ruby's
  standard credential provider chain. In practice, this means a shared
  credential file or environment variables with your credentials. These tests
  may have some AWS costs associated with running them since AWS resources are
  created and destroyed within these tests.

  Background:
    Given an aws-record model with definition:
      """
      integer_attr :forum_id, hash_key: true
      integer_attr :post_id, range_key: true
      string_attr  :forum_name
      string_attr  :post_title
      string_attr  :post_body
      integer_attr :author_id
      string_attr  :author_name
      """

  Scenario: Create a DynamoDB Table with a Local Secondary Index
    When we add a local secondary index to the model with parameters:
      """
      [
        "title",
        {
          "range_key": "post_title",
          "projection": {
            "projection_type": "INCLUDE",
            "non_key_attributes": [
              "post_body"
            ]
          }
        }
      ]
      """
    And we create a table migration for the model
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
    And the table should have a local secondary index named "title"

  Scenario: Create a DynamoDB Table with a Global Secondary Index
    When we add a global secondary index to the model with parameters:
      """
      [
        "author",
        {
          "hash_key": "forum_name",
          "range_key": "author_name",
          "projection": {
            "projection_type": "ALL"
          }
        }
      ]
      """
    And we create a table migration for the model
    And we call 'create!' with parameters:
      """
      {
        "provisioned_throughput": {
          "read_capacity_units": 1,
          "write_capacity_units": 1
        },
        "global_secondary_index_throughput": {
          "author": {
            "read_capacity_units": 1,
            "write_capacity_units": 1
          }
        }
      }
      """
    Then eventually the table should exist in DynamoDB
    And the table should have a global secondary index named "author"
