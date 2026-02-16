import 'dart:convert';
import '../config/api_config.dart';
import 'network_client.dart';
import 'network_exceptions.dart';

class GraphQLService {
  GraphQLService._();
  static final instance = GraphQLService._();

  String _endpoint = '';

  void init({String? uri}) {
    _endpoint = uri ?? _guessGraphqlFromBase();
  }

  String _guessGraphqlFromBase() {
    final base = ApiConfig.baseUrl;
    if (base.endsWith('/api')) return base.replaceFirst('/api', '/graphql');
    return '$base/graphql';
  }

  Future<List<Map<String, dynamic>>> fetchRecipes({String? search}) async {
    final query = r'''
      query FetchRecipes($q: String) {
        recipes(search: $q) {
          id
          title
          description
          calories
          proteins
          fats
          carbs
          imageUrl
          cookingTime
          difficulty
        }
      }
    ''';

    try {
      final uri = Uri.parse(_endpoint);
      final body = jsonEncode({'query': query, 'variables': {'q': search}});
      final res = await NetworkClient.instance.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        if (m['errors'] != null) {
          final first = (m['errors'] as List).isNotEmpty ? (m['errors'] as List).first : null;
          throw ApiException(500, first != null ? first['message'] ?? first.toString() : 'GraphQL error');
        }
        final data = m['data']?['recipes'] as List<dynamic>?;
        if (data == null) return [];
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw ApiException(res.statusCode, res.body);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> input) async {
    final mutation = r'''
      mutation CreateRecipe($input: CreateRecipeInput!) {
        createRecipe(input: $input) {
          id
          title
        }
      }
    ''';

    try {
      final uri = Uri.parse(_endpoint);
      final body = jsonEncode({'query': mutation, 'variables': {'input': input}});
      final res = await NetworkClient.instance.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        if (m['errors'] != null) {
          final first = (m['errors'] as List).isNotEmpty ? (m['errors'] as List).first : null;
          throw ApiException(500, first != null ? first['message'] ?? first.toString() : 'GraphQL error');
        }
        final data = m['data']?['createRecipe'] as Map<String, dynamic>?;
        return data ?? {};
      }
      throw ApiException(res.statusCode, res.body);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }
}
