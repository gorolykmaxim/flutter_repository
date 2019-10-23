import 'package:flutter_repository/flutter_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockException extends Mock implements Exception {}
class MockDataSource extends Mock implements DataSource {}
class MockDataSourceServant extends Mock implements DataSourceServant {}

void main() {
  group('Specification', () {
    Specification specification;
    setUp(() {
      specification = Specification();
    });
    test('creates specification with every existing simple condition type in it', () {
      specification.equals("field1", 15);
      specification.lessThan("field2", 32.2);
      specification.greaterThan("field3", -5);
      specification.contains("field4", "word");
      specification.contains("field5", "WoRD", ignoreCase: true);
      specification.limit = 100;
      specification.offset = 200;
      specification.appendOrderDefinition(Order.ascending("field1"));
      specification.appendOrderDefinition(Order.descending("field2"));
      expect(specification.conditions, [
        Condition.equals("field1", 15),
        Condition.lessThan("field2", 32.2),
        Condition.greaterThan("field3", -5),
        Condition.contains("field4", "word", ignoreCase: false),
        Condition.contains("field5", "WoRD", ignoreCase: true)
      ]);
      expect(specification.limit, 100);
      expect(specification.offset, 200);
      expect(specification.orderDefinitions, [Order.ascending("field1"), Order.descending("field2")]);
    });
    test('creates specification that should have limit and offset set ot null by default', () {
      expect(specification.limit, isNull);
      expect(specification.offset, isNull);
    });
    test('creates specification with "or" condition, that has two "and" conditions in it', () {
      Condition and1 = Condition.and([]);
      Condition and2 = Condition.and([]);
      Condition or = Condition.or([and1, and2]);
      specification.add(or);
      expect(specification.conditions, [or]);
    });
    test('replaces current conditions of the specification with the ones from the specified one', () {
      specification.equals("name", 'Tom');
      specification.equals('city', 'New York');
      specification.equals('phone', '829344');
      specification.equals('age', 15);
      specification.greaterThan('income', 352);
      specification.add(Condition.or([Condition.equals('family', true), Condition.equals('ownFamily', true)]));
      specification.limit = 15;
      specification.offset = 0;
      final other = Specification();
      other.equals('name', 'Frank');
      other.equals('city', 'Los Angeles');
      other.equals('phone', '354263');
      specification.insertConditionsFrom(other);
      expect(specification.conditions, [
        Condition.equals('age', 15),
        Condition.greaterThan('income', 352),
        Condition.or([Condition.equals('family', true), Condition.equals('ownFamily', true)]),
        Condition.equals('name', 'Frank'),
        Condition.equals('city', 'Los Angeles'),
        Condition.equals('phone', '354263')
      ]);
      expect(specification.limit, 15);
      expect(specification.offset, 0);
    });
  });
  group('Collection', () {
    final specification = Specification();
    DataSource dataSource;
    DataSourceServant<Object> servant;
    Collection<Object> objects;
    final expectedObjects = [Object(), Object(), Object()];
    final persistentObjects = [{"field1": 15}, {"field1": 32}, {"field1": -5}];
    setUp(() {
      dataSource = MockDataSource();
      when(dataSource.find(specification)).thenAnswer((_) => Future.value(persistentObjects));
      servant = MockDataSourceServant();
      for (var i = 0; i < expectedObjects.length; i++) {
        when(servant.deserialize(persistentObjects[i])).thenReturn(expectedObjects[i]);
        when(servant.serialize(expectedObjects[i])).thenReturn(persistentObjects[i]);
        when(servant.idFieldNames).thenReturn(["field1"]);
      }
      objects = Collection(dataSource, servant);
    });
    test('finds all entities matching the pattern', () async {
      expect(await objects.findAll(specification), expectedObjects);
    });
    test('fails to find all entities matching the pattern due to some underlying exception', () async {
      when(dataSource.find(specification)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.findAll(specification), throwsA(isInstanceOf<EntitiesLookupException>()));
    });
    test('finds only one entity in the collection, that matches the specification', () async {
      when(dataSource.find(specification)).thenAnswer((_) => Future.value([persistentObjects[0]]));
      expect(await objects.findOne(specification), expectedObjects[0]);
    });
    test('fails to find only one entity matching the specification, since there are several such entities', () async {
      expect(objects.findOne(specification), throwsA(isInstanceOf<UnexpectedCollectionSizeException>()));
    });
    test('fails to find only one entity matching the specification, since there are no such entities', () async {
      when(dataSource.find(specification)).thenAnswer((_) => Future.value([]));
      expect(objects.findOne(specification), throwsA(isInstanceOf<UnexpectedCollectionSizeException>()));
    });
    test('finds several entities, matching the specification, but returns only the first one', () async {
      expect(await objects.findFirst(specification), expectedObjects[0]);
    });
    test('fails to find first entity, since there are no matching entities', () async {
      when(dataSource.find(specification)).thenAnswer((_) => Future.value([]));
      expect(objects.findFirst(specification), throwsA(isInstanceOf<UnexpectedCollectionSizeException>()));
    });
    test('adds new entity to the collection', () async {
      await objects.add(expectedObjects[0]);
      expect(verify(dataSource.create(captureAny)).captured.single, [EntityContext(persistentObjects[0], servant.idFieldNames)]);
    });
    test('fails to add an entity to the collection due to some exception', () async {
      when(dataSource.create(any)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.add(expectedObjects[0]), throwsA(isInstanceOf<ModificationException>()));
    });
    test('adds multiple entities to the collection', () async {
      await objects.addAll(expectedObjects);
      expect(verify(dataSource.create(captureAny)).captured.single, persistentObjects.map((p) => EntityContext(p, servant.idFieldNames)));
    });
    test('fails to add multiple entities to the collection due to some exception', () async {
      when(dataSource.create(any)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.addAll(expectedObjects), throwsA(isInstanceOf<ModificationException>()));
    });
    test('update a copy of an entity, that is already present in the collection', () async {
      await objects.update(expectedObjects[0]);
      expect(verify(dataSource.update(captureAny)).captured.single, EntityContext(persistentObjects[0], servant.idFieldNames));
    });
    test('fails to update a copy of an entity, stored in the collection, due to some exception', () async {
      when(dataSource.update(any)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.update(expectedObjects[0]), throwsA(isInstanceOf<ModificationException>()));
    });
    test('removes specified entity from the collection', () async {
      await objects.removeOne(expectedObjects[0]);
      expect(verify(dataSource.remove(captureAny)).captured.single, [EntityContext(persistentObjects[0], servant.idFieldNames)]);
    });
    test('fails to remove specified entity from the collection due to some exception', () async {
      when(dataSource.remove(any)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.removeOne(expectedObjects[0]), throwsA(isInstanceOf<ModificationException>()));
    });
    test('removes multiple specified entities from the collection', () async {
      await objects.removeAll(expectedObjects);
      expect(verify(dataSource.remove(captureAny)).captured.single, persistentObjects.map((p) => EntityContext(p, servant.idFieldNames)));
    });
    test('fails to remove multiple specified entities from the collection due to some exception', () async {
      when(dataSource.remove(any)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.removeAll(expectedObjects), throwsA(isInstanceOf<ModificationException>()));
    });
    test('removes all entities from the collection, that match a specification', () async {
      await objects.remove(specification);
      verify(dataSource.removeMatching(specification));
    });
    test('fails to remove entities, matching the specification, due to some exception', () async {
      when(dataSource.removeMatching(any)).thenAnswer((_) => Future.error(MockException()));
      expect(objects.remove(specification), throwsA(isInstanceOf<ModificationException>()));
    });
  });
}
