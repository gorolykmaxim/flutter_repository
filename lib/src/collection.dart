import 'data.dart';
import 'specification.dart';

/// A generic [Collection]-related [Exception].
class CollectionException implements Exception {
  final String message;

  /// Create an [Exception] with the specified [message].
  CollectionException(this.message);

  @override
  String toString() => message;
}

/// Failed to look for entities in a [Collection].
class EntitiesLookupException extends CollectionException {

  /// [Exception] that caused [EntitiesLookupException] to happen.
  final Exception cause;

  /// Failed to lookup entities using the [specification] due to [cause].
  EntitiesLookupException(Specification specification, this.cause): super('Failed to find entities usign $specification. Reason: $cause');
}

/// During entities lookup a number of entities was found that didn't match
/// the expected amount.
class UnexpectedCollectionSizeException extends CollectionException {

  /// Count of entities that was [expected] and the [actual] count.
  final int expected, actual;

  /// [specification] used during the lookup.
  final Specification specification;

  /// [actual] count of entities was found while expecting to find [expected]
  /// count using the [specification].
  UnexpectedCollectionSizeException(this.expected, this.actual, this.specification): super('Found $actual entities using $specification. Expected to find $expected.');
}

/// Failed to modify a [Collection].
class ModificationException extends CollectionException {
  /// [cause] of [ModificationException].
  final Exception cause;

  /// Failed to perform [action] on the [entities] stored in a [Collection]
  /// due to the [cause].
  ModificationException.entities(String action, Iterable<Object> entities, this.cause): super('Failed to $action $entities. Reason: $cause');

  /// Failed to [action] entities in a [Collection], that match the
  /// [specification] due to the [cause].
  ModificationException.specification(String action, Specification specification, this.cause): super('Failed to $action entities using $specification. Reason: $cause');
}

/// A base class for a [Collection] and [ImmutableCollection].
///
/// All inheritors of this class use some sort of [DataSource] implementation
/// to store entities in.
abstract class BaseCollection<T> {
  final DataSource _dataSource;
  final DataSourceServant _servant;

  /// Create a [Collection] that relies on the [_dataSource] to store it's
  /// entities in and uses [_servant] to serialize and deserialize those
  /// entities.
  BaseCollection(this._dataSource, this._servant);
}

/// A [Collection] that can't be modified.
///
/// The [ImmutableCollection] is a good abstraction for data sources,
/// that are used in an application only as a sources of data and for various
/// reasons can't be modified.
class ImmutableCollection<T> extends BaseCollection<T> {

  /// Create an [ImmutableCollection] that will query entities from [dataSource]
  /// and deserialize them using [servant].
  ImmutableCollection(DataSource dataSource, DataSourceServant servant) : super(dataSource, servant);

  /// Find all entities in this [ImmutableCollection], that match the
  /// [specification].
  Future<List<T>> findAll(Specification specification) async {
    try {
      List<Map<String, dynamic>> entities = await _dataSource.find(specification);
      return entities.map(_servant.deserialize).toList();
    } on Exception catch (e) {
      throw EntitiesLookupException(specification, e);
    }
  }

  /// Find only one entity in this [ImmutableCollection] using the
  /// [specification].
  ///
  /// If the [ImmutableCollection] can't return precisely one entity
  /// (e.g. there is either 0 or more than 1 entities like it) -
  /// [UnexpectedCollectionSizeException] will be thrown.
  Future<T> findOne(Specification specification) async {
    List<T> entities = await findAll(specification);
    num entitiesFound = entities.length;
    if (entitiesFound != 1) {
      throw UnexpectedCollectionSizeException(1, entitiesFound, specification);
    }
    return entities[0];
  }

  /// Find entities in this [ImmutableCollection] that match the [specification]
  /// and return only the first one of them.
  ///
  /// If [ImmutableCollection] contains no such entities - [ImmutableCollection]
  /// will throw [UnexpectedCollectionSizeException].
  Future<T> findFirst(Specification specification) async {
    List<T> entities = await findAll(specification);
    if (entities.isEmpty) {
      throw UnexpectedCollectionSizeException(1, 0, specification);
    }
    return entities[0];
  }
}

/// A [Collection] of entities, that stores copies of those entities.
///
/// The fact that the [Collection] stores copies instead of actual objects
/// means that each you want to update an object, that is stored in the
/// [Collection] you would have to explicitly propagate that change
/// to the [Collection] using [update].
class Collection<T> extends ImmutableCollection<T> {

  /// Create a [Collection], that will store entities in the [dataSource]
  /// and serialize/deserialize them using [servant].
  Collection(DataSource dataSource, DataSourceServant servant) : super(dataSource, servant);

  /// Add [entity] to the [Collection].
  Future<void> add(T entity) async {
    try {
      await _dataSource.create([_createEntityContext(entity)]);
    } on Exception catch (e) {
      throw ModificationException.entities('add', [entity], e);
    }
  }

  /// Add all [entities] to the [Collection].
  ///
  /// [addAll] is expected to be more efficient for adding multiple entities
  /// to the [Collection] than calling [add] multiple times in a loop.
  Future<void> addAll(Iterable<T> entities) async {
    try {
      await _dataSource.create(entities.map(_createEntityContext));
    } on Exception catch (e) {
      throw ModificationException.entities('add', entities, e);
    }
  }

  /// Update [entity], that is already present in the [Collection].
  Future<void> update(T entity) async {
    try {
      await _dataSource.update(_createEntityContext(entity));
    } on Exception catch (e) {
      throw ModificationException.entities('update', [entity], e);
    }
  }

  /// Remove [entity] from the [Collection].
  Future<void> removeOne(T entity) async {
    try {
      await _dataSource.remove([_createEntityContext(entity)]);
    } on Exception catch (e) {
      throw ModificationException.entities('remove', [entity], e);
    }
  }

  /// Remove all [entities] from the [Collection].
  ///
  /// [removeAll] is expected to be more efficient for removing multiple
  /// entities from the [Collection] than calling [removeOne] multiple times
  /// in a loop.
  Future<void> removeAll(Iterable<T> entities) async {
    try {
      await _dataSource.remove(entities.map(_createEntityContext));
    } on Exception catch (e) {
      throw ModificationException.entities('remove', entities, e);
    }
  }

  /// Remove all entities from the [Collection] that match the [specification].
  ///
  /// Expected to be as effective for removal of multiple entities as a
  /// [removeAll].
  Future<void> remove(Specification specification) async {
    try {
      await _dataSource.removeMatching(specification);
    } on Exception catch (e) {
      throw ModificationException.specification('remove', specification, e);
    }
  }

  EntityContext _createEntityContext(T entity) {
    return EntityContext(_servant.serialize(entity), _servant.idFieldNames);
  }
}