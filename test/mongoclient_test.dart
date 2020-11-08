import 'package:mongoclient/mongoclient.dart';
import 'package:test/test.dart';
import 'package:mock_data/mock_data.dart';
import 'dart:convert';

void main() {
  group('Authentication', () {
    MongoDbClient db;
    final username =
        (mockName() + '@' + mockUrl().split('/').last).replaceAll(' ', '');
    final document = {
      "firstName": username.split('@').first,
      "lastName": mockName('male'),
      'email': username,
      "age": 24,
    };
    final List<Map<String, dynamic>> documents = [];

    final model = 'test';
    setUp(() {
      db = MongoDbClient();
      for (int i = 0; i < 10; i++) {
        final email =
            (mockName() + '@' + mockUrl().split('/').last).replaceAll(' ', '');
        documents.add({
          'email': email,
          'firstName': email.split('@').first,
          'age': mockInteger(21, 40),
        });
      }
    });

    test('Server Address and Port', () {
      expect(db.config.serverAddress, 'localhost:8888');
    });
    test('register $username with password 123456#aA', () async {
      ClientResponse response = await db.authenticate(
          username, '123456#aA', AuthAction.signUpWithPassword);
      expect(response.status, equals(200));
    });
    test('login user', () async {
      ClientResponse response = await db.authenticate(
          username, '123456#aA', AuthAction.signInWithPassword);
      expect(response.status, equals(200));
    });
    test('Allow temporary access to a Model', () async {
      final response = await db.allowModel(model);
      expect(response.status, equals(200));
    });
    test('Create Index on $model.email', () async {
      final response = await db.createIndex(
        model,
        name: 'email',
        keys: {'email': 1},
        unique: true,
      );
      expect(response.status, equals(200));
    });
    test('Insert a record in $model model', () async {
      var response = await db.createDocuments(model, document);
      expect(response.status, equals(200));
    });

    test('Insert 10 records in $model', () async {
      var response = await db.createDocuments(model, documents);
      int count =
          response.status == 200 ? json.decode(response.body)['count'] : 0;
      expect(count, equals(documents.length));
    });
    test('login as admin', () async {
      final response = await db.authenticate(
        'ads',
        '123456#aA',
        AuthAction.signInWithPassword,
      );
      expect(response.status, equals(200));
    });

    test('delete $username', () async {
      await db.authenticate(
        'ads',
        '123456#aA',
        AuthAction.signInWithPassword,
      );
      final response = await db.remove('user', {'username': username});
      expect(response.status, equals(200));
    });
  });
}
