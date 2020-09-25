import 'package:mongoclient/mongoclient.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    MongoDbClient awesome;

    setUp(() {
      awesome = MongoDbClient();
    });

    test('First Test', () {
      expect(awesome.config.serverAddress, isTrue);
    });
  });
}
