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
@dynamodb @table
Feature: Amazon DynamoDB Tables with On Demand Billing
  This feature tests the integration of model classes that include the
  Aws::Record module with the Aws::Record::TableMigration class, which helps to
  run table change operations on DynamoDB. To run these tests, you will need to
  have valid AWS credentials that are accessible with the AWS SDK for Ruby's
  standard credential provider chain. In practice, this means a shared
  credential file or environment variables with your credentials. These tests
  may have some AWS costs associated with running them since AWS resources are
  created and destroyed within these tests.

  Scenario: Create a DynamoDB Table with on-demand billing with aws-record
    Given an aws-record model with data:
      """
      [
        { "method": "string_attr", "name": "id", "hash_key": true },
        { "method": "integer_attr", "name": "count", "range_key": true },
        { "method": "string_attr", "name": "body", "database_name": "content" }
      ]
      """
    When we create a table migration for the model
    And we call 'create!' with parameters:
      """
      { "billing_mode": "PAY_PER_REQUEST" }
      """
    Then eventually the table should exist in DynamoDB
    And calling 'table_exists?' on the model should return "true"
    And calling "provisioned_throughput" on the model should return:
      """
      {
        "read_capacity_units": 0,
        "write_capacity_units": 0
      }
      """
