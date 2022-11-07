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

@dynamodb @inheritance
Feature: Amazon DynamoDB Inheritance
  This feature tests inheritance between parent class and child classes. To run
  these tests, you will need to have valid AWS credentials that are accessible
  with the AWS SDK for Ruby's standard credential provider chain. In practice,
  this means a shared credential file or environment variables with your credentials.
  These tests may have some AWS costs associated with running them since AWS resources
  are created and destroyed within these tests.


  Background:
    Given a "Parent" model with definition:
      """
      set_table_name('Animal')
      integer_attr  :id,    hash_key: true
      string_attr :name, range_key: true
      string_attr :size
      """

