import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_eating_flutter/services/graphql_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('GraphQLService init creates client', () {
    expect(() => GraphQLService.instance.init(uri: 'https://example.com/graphql'), returnsNormally);
  });
}
