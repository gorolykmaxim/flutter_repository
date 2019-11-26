import 'package:collection/collection.dart';
import 'specification.dart';

const _iterableEquality = IterableEquality();

/// Representation of an entity that should be modified in the [DataSource].
class EntityContext {

  /// Entity that should be modified, presented as a plain [Map].
  final Map<String, dynamic> entity;

  /// Name of entity's fields, that together should be treated as entity's
  /// identity.
  final Iterable<String> idFieldNames;

  /// Constructs [EntityContext] of the [entity]. Also supply collection of
  /// field names, that together should be treated as [entity]'s ID, in
  /// [idFieldNames].
  EntityContext(this.entity, this.idFieldNames);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EntityContext &&
              runtimeType == other.runtimeType &&
              entity == other.entity &&
              _iterableEquality.equals(idFieldNames, other.idFieldNames);

  @override
  int get hashCode =>
      entity.hashCode ^
      idFieldNames.hashCode;

  @override
  String toString() {
    return 'EntityContext{entity: $entity, idFieldNames: $idFieldNames}';
  }
}

/// Abstract read-only [DataSource] that only allows querying it's data.
abstract class ReadonlyDataSource {

  /// Find collection of entities, stored in [DataSource], that match the
  /// [specification].
  Future<List<Map<String, dynamic>>> find(Specification specification);
}

/// Abstract [DataSource] that contains data and allows it's modification.
///
/// [DataSource] can be anything: database, third-party HTTP API, file system
/// etc.
abstract class DataSource extends ReadonlyDataSource {

  /// Saves specified [entityContexts] in [DataSource], that were not previously
  /// present there.
  ///
  /// If at least one of [entityContexts] is already present in [DataSource],
  /// [DataSource] might throw an exception.
  Future<void> create(Iterable<EntityContext> entityContexts);

  /// Updates [entityContext], that is already contained by [DataSource].
  ///
  /// If [entityContext] is not present in [DataSource], [DataSource] might
  /// throw an exception.
  Future<void> update(EntityContext entityContext);

  /// Removes [entityContexts] from [DataSource].
  ///
  /// If at least one of [entityContexts] is not present in [DataSource],
  /// [DataSource] might throw an exception.
  Future<void> remove(Iterable<EntityContext> entityContexts);

  /// Removes entities from [DataSource], that match specified [specification].
  Future<void> removeMatching(Specification specification);
}

/// A servant, that transforms domain entities into persistable property
/// containers and vice-versa.
abstract class DataSourceServant<T> {

  /// Returns list of field names of entities, stored in the corresponding
  /// [DataSource], that should be treated as an identity of those entities.
  Iterable<String> get idFieldNames;

  /// Turns domain entity object into a generic property container, that will
  /// be stored in [DataSource].
  Map<String, dynamic> serialize(T entity);

  /// Turns property container, that was previously stored in [DataSource],
  /// into a corresponding domain entity.
  T deserialize(Map<String, dynamic> entity);
}