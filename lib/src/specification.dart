import 'package:collection/collection.dart';

const _iterableComparator = IterableEquality();

enum ConditionType {
  equals, lessThan, greaterThan, contains, containsIgnoreCase, and, or
}

/// A [Condition] that an entity, stored in a [Collection], may match.
///
/// Used by [Specification] to select sets of entities stored in [Collection],
/// which match all of [Specification]'s [Condition]s.
class Condition {

  /// Name of entity's field, that should be checked by this [Condition].
  /// null if the [Condition] is either [ConditionType.or] or
  /// [ConditionType.and].
  final String field;

  /// Value, against which entity field's value should be checked.
  /// null if the [Condition] is either [ConditionType.or] or
  /// [ConditionType.and].
  final dynamic value;

  /// Comparison type, that will be applied to entity's value and [value].
  final ConditionType type;

  /// Child [Condition]s of this [Condition].
  /// Only [ConditionType.or] and [ConditionType.and] [Condition]s can have
  /// child [Condition]s. Conditions with other [type] will have [children]
  /// as an empty list.
  Iterable<Condition> children = [];

  /// Creates a [Condition], that will check if value of entity's [field] is
  /// equal to [value].
  Condition.equals(this.field, this.value): type = ConditionType.equals;

  /// Creates a [Condition], that will check if value of entity's [field] is
  /// less than [value].
  Condition.lessThan(this.field, this.value): type = ConditionType.lessThan;

  /// Creates a [Condition], that will check if value of entity's [field] is
  /// greater than [value].
  Condition.greaterThan(this.field, this.value): type = ConditionType.greaterThan;

  /// Creates a [Condition], that will check if value of entity's [field]
  /// contains [value].
  ///
  /// If [ignoreCase] is set to true, then [String]-based checks will be
  /// conducted without considering characters' register. By default
  /// [ignoreCase] is set to false.
  Condition.contains(this.field, this.value, {ignoreCase = false}): type = ignoreCase ? ConditionType.containsIgnoreCase : ConditionType.contains;

  /// Creates a [Condition], which will match an entity only if all of
  /// [children] will match that entity.
  Condition.and(this.children): field = null, value = null, type = ConditionType.and;

  /// Creates a [Condition], which will match an entity if at least on of
  /// [children] will match that entity.
  Condition.or(this.children): field = null, value = null, type = ConditionType.or;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Condition &&
              runtimeType == other.runtimeType &&
              field == other.field &&
              value == other.value &&
              type == other.type &&
              _iterableComparator.equals(children, other.children);

  @override
  int get hashCode =>
      field.hashCode ^
      value.hashCode ^
      type.hashCode ^
      children.hashCode;
}

enum OrderType {
  asc, desc
}

/// [Order] definition for results, returned by [Specification].
class Order {

  /// Name of a field, by which results should be ordered.
  final String field;

  /// Type of the ordering that should be applied.
  final OrderType type;

  /// Order [Specification] results by [field] in ascending order.
  Order.ascending(this.field): type = OrderType.asc;

  /// Order [Specification] results by [field] in descending order.
  Order.descending(this.field): type = OrderType.desc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Order &&
              runtimeType == other.runtimeType &&
              field == other.field &&
              type == other.type;

  @override
  int get hashCode =>
      field.hashCode ^
      type.hashCode;
}

/// A [Specification], that describes a set of entities in a [Collection] or
/// [ImmutableCollection].
///
/// [Specification] can be used to describe properties of entities, stored in
/// [Collection]. Based of such [Specification] a selection of entities,
/// contained in the [Collection], can be made.
///
/// [Specification] is a simple collection of [Condition]s, combination
/// of which defines a [Specification] of which entities should be selected.
/// A [Specification] only applies to an entity if all of it's [Condition]s
/// match the entity, so the [Specification] itself can be treated as an "and"
/// statement.
class Specification {
  List<Condition> _conditions = [];
  List<Order> _orderDefinitions = [];

  /// Maximum amount of entities that can be returned using this [Specification].
  ///
  /// If the value is not set explicitly here, then an actual [DataSource]
  /// implementation, used by queried [Collection] decides it.
  int limit;

  /// Offset to be taken for entities, returned using this [Specification].
  ///
  /// Measured in actual entities rather than in pages of entities.
  ///
  /// If the value is not set explicitly here, then an actual [DataSource]
  /// implementation, used by queried [Collection] decides it.
  int offset;

  /// Returns all [Condition]s, of this [Specification].
  List<Condition> get conditions => List<Condition>.from(_conditions);

  /// Returns definition of [Order] in which results of this [Specification]
  /// should be ordered.
  ///
  /// Single specification can have multiple [Order] definitions and all of them
  /// are stored in a particular order (no pun intended).
  List<Order> get orderDefinitions => List<Order>.from(_orderDefinitions);

  /// Adds an equality [Condition] to this [Specification].
  ///
  /// An entity will be selected from a [Collection] if it's [field] is
  /// strictly equal to the [value].
  void equals(String field, dynamic value) => _conditions.add(Condition.equals(field, value));

  /// Adds a "less-than" comparison [Condition] to this [Specification].
  ///
  /// An entity will be selected from a [Collection] if it's [field]'s value
  /// is less than [value].
  void lessThan(String field, dynamic value) => _conditions.add(Condition.lessThan(field, value));

  /// Adds a "greater-than" comparison [Condition] to this [Specification].
  ///
  /// An entity will be selected from a [Collection] if it's [field]'s value
  /// is greater than [value].
  void greaterThan(String field, dynamic value) => _conditions.add(Condition.greaterThan(field, value));

  /// Adds a [Condition] to this [Specification] that will check if value
  /// of entity's [field] "contains" the [value].
  ///
  /// The meaning of the word "contains" depends on the actual data type of
  /// the [field]. For example, if the [field] is a [String], then the
  /// [Condition] will check if the [value] is a sub-string of the [field]'s
  /// value.
  ///
  /// For [String]-related checks, if [ignoreCase] is set to true, then the
  /// case of strings compared will not be taken into a consideration. By
  /// default [ignoreCase] is false.
  void contains(String field, dynamic value, {ignoreCase = false}) => _conditions.add(Condition.contains(field, value, ignoreCase: ignoreCase));

  /// Adds specified [Condition] to this [Specification].
  void add(Condition condition) => _conditions.add(condition);

  /// Defines the [order] in which results, matching this [Specification],
  /// should be returned.
  ///
  /// Single [Specification] can have multiple [Order] definitions in case
  /// there is a need to order results by multiple fields.
  void appendOrderDefinition(Order order) => _orderDefinitions.add(order);

  /// Add [Condition]s from the [specification] to this [Specification].
  ///
  /// If a [Condition] of this [Specification] references a field name,
  /// that is present in ones of [specification] [Condition]s, it will be
  /// overridden.
  void insertConditionsFrom(Specification specification) {
    final theirConditionFields = specification.conditions
        .where((c) => c.children.isEmpty)
        .map((c) => c.field)
        .toSet();
    _conditions = _conditions
        .where((c) => !theirConditionFields.contains(c.field))
        .toList();
    _conditions.addAll(specification.conditions);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Specification &&
              runtimeType == other.runtimeType &&
              _iterableComparator.equals(_conditions, other._conditions) &&
              limit == other.limit &&
              offset == other.offset;

  @override
  int get hashCode =>
      _conditions.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}