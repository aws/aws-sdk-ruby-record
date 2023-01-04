# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
      integer_attr :id, hash_key: true
      string_attr :dish, range_key: true
      boolean_attr :spicy
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
    Then eventually the table should exist in DynamoDB
    And a Child model with definition:
      """
        set_table_name('DessertTable')
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
    Then eventually the table should exist in DynamoDB

