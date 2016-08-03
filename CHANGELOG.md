1.0.0.pre.10 (2016-08-03)
------------------

* Feature - Aws::Record - Refactored tracking of model attributes, key attributes,
  and item data to use internal classes over module composition. Dirty tracking is
  also handled more consistently across attributes, and turning on/off of dirty
  tracking is only possible at the model level (not for individual attributes).

1.0.0.pre.9 (2016-07-22)
------------------

* Feature - Aws::Record::Attribute - Added support for default values at the attribute
  level.

* Feature - Aws::Record::Marshalers - Removed the marshalers in the `Aws::Attributes`
  namespace, replacing them with instantiated marshaler objects. This enables
  more functionality in marshalers such as the Date/DateTime marshalers.

* Feature - Aws::Record::DirtyTracking - Improves dirty tracking by adding
  support for tracking mutations of attribute value objects. This feature is on
  by default for the "collection" types: `:list_attr`, `:map_attr`,
  `:string_set_attr`, and `:numeric_set_attr`.
  
  Before this feature, the `#save` method's default behavior of running an
  update call for dirty attributes only could cause problems for users of
  collection attributes. As many of them are commonly manipulated using mutable
  state, the underlying "clean" version of the objects would be modified and the
  updated object would not be recognized as dirty, and therefore would not be
  updated at all unless explicitly marked as dirty or through a force put.
  
  ```ruby
  class Model
    include Aws::Record
    string_attr :uuid, hash_key: true
    list_attr :collection
  end
  
  item = Model.new(uuid: SecureRandom.uuid, collection: [1,2,3])
  item.clean! # As if loaded from the database, to demonstrate the new tracking.
  item.dirty? # => false
  item.collection << 4 # In place mutation of the "collection" array.
  item.dirty? # => true (Previous versions would not recognize this as dirty.
  item.save # Would call Aws::DynamoDB::Client#update_item for :collection only.
  ```
  
  Note that this feature is implemented using deep copies of collection objects
  in memory, so there is a potential memory/performance hit in exchange for the
  added accuracy. As such, mutation tracking can be explicitly turned off at the
  attribute level or at the full model level, if desired.
  
  ```ruby
  # Note that the disabling of mutation tracking is redundant in this example,
  # for illustration purposes.
  class Model
    include Aws::Record
    disable_mutation_tracking # For turning off mutation at the model level.
    string_attr :uuid, hash_key: true
    list_attr :collection, mutation_tracking: false # Turn off at attr level.
  end
  ```

1.0.0.pre.8 (2016-05-19)
------------------

* Feature - Aws::Record - Adds the ability to set initial attribute values when
  calling `#initialize`. Additionally, can call `update` on a model to directly
  call `Aws::DynamoDB::Client#update_item`.

1.0.0.pre.7 (2016-04-21)
------------------

* Upgrading - Aws::Record - This release includes changes to validation and
  to the `#save` and `#save!` methods. With this release, the validation hooks
  in `Aws::Record::Attribute` have been removed. Additionally, `#save` will
  resume raising exceptions on client errors. However, `#save` and `#save!`
  will attempt to call `#valid?` if defined on the model, and will return false
  or raise as appropriate if that method is defined and returns false.
  
  As a part of this change, we've removed the built in `#valid?` and `#errors`
  methods. If you were a user of those, consider bringing your own validation
  library such as `ActiveModel::Validations`.

* Issue - Aws::Record - Removes `#valid?` and `#errors` methods, which caused a
  conflict with the ability to bring your own validation library such as
  `ActiveModel::Validations`. Added tests as an example and to test
  compatibility.

1.0.0.pre.6 (2016-04-19)
------------------

* Feature - Aws::Record::Attributes - Improves default marshaling behavior for
  set types. Now, if your object responds to `:to_set`, such as an Array, it
  will automatically be marshaled to a set type when persisted.

1.0.0.pre.5 (2016-04-19)
------------------

* Upgrading - Aws::Record - The conditional put/update logic added to `#save`
  and `#save!` is not backwards compatible in some cases. For example, the
  following code would work in previous versions, but not in this version:
  
  ```ruby
  item = Model.new # Assume :id is the hash key, there is no range key.
  item.id = 1
  item.content = "First write."
  item.save
  
  smash = Model.new
  smash.id = 1
  smash.content = "Second write."
  smash.save # false, and populates the errors array.
  smash.save(force: true) # This will skip the conditional check and work.
  
  updatable = Model.find(id: 1)
  updatable.content = "Update write."
  updatable.save # This works and uses an update client call.
  ```
  
  If you want to maintain previous behavior of unconditional puts, add the
  `force: true` option to your `#save` calls. However, this risks overwriting
  unmodeled attributes, or attributes excluded from your projection. But, the
  option is available for you to use.
  
* Upgrading - Aws::Record - The split of the `#save` method into `#save` and
  `#save!` breaks when your code is expecting `#save` to raise exceptions.
  `#save` will return false on a failed write and populate an `errors` array.
  If you wish to raise exceptions on failed save attempts, use the `#save!`
  method.

* Feature - Aws::Record - Adds logic to determine if `#save` and `#save!` calls
  should use `Aws::DynamoDB::Client#put_item` or
  `Aws::DynamoDB::Client#update_item`, depending on which item attributes are
  marked as dirty. `#put_item` calls are also made conditional on the key not
  existing, so accidental overwrites can be prevented. Old behavior of
  unconditional `#put_item` calls can be done using the `force: true` parameter.

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
