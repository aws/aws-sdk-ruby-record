Unreleased Changes
------------------

* Feature - Aws::Record - Separates the `#save` method into `#save` and
  `#save!`. `#save!` will raise any errors that occur during persistence, while
  `#save` will populate an errors array and cause `#valid?` calls on the item to
  return `false`.

* Issue - Aws::Record - Changed how default table names are generated. In the
  past, the default table name could not handle class names that included
  modules. Now, module namespaces are appended to the default table name. This
  should not affect any existing model classes, as previously any affected
  models would have failed to create a table in DynamoDB.

1.0.0.pre.4 (2016-02-11)
------------------

* Feature - Aws::Record::DirtyTracking - `Aws::Record` items will now keep track
  of "dirty" changes from database state. The DirtyTracking module provides a
  set of helper methods to handle dirty attributes.

1.0.0.pre.3 (2016-02-10)
------------------

* Feature - Aws::Record - Support for additional marshaled types, such as lists,
  maps, and string/numeric sets.

1.0.0.pre.2 (2016-02-04)
------------------

* Feature - Aws::Record - Provides a low-level interface for the client `#query`
  and `#scan` methods. Query and Scan results are surfaces as an enumerable
  collection of `Aws::Record` items.

* Feature - Aws::Record - Support for adding global secondary indexes and local
  secondary indexes to your model classes. Built-in support for creating these
  indexes at table creation time.

1.0.0.pre.1 (2015-12-23)
------------------

* Feature - Aws::Record - Initial development release of the `aws-record` gem.
  Includes basic table and item functionality for CRUD operations.
