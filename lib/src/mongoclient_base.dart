import 'dart:convert';
import 'dart:io';
import 'package:mongoclient/mongoclient.dart';
import 'app_configuration.dart';
import 'package:http/http.dart' as http;

class MongoDbClient {
  AppConfig config = AppConfig();
  String _url;
  final headers = {'content-type': 'Application/json'};
  Map<String, dynamic> auth = {};
  MongoDbClient({Map<String, dynamic> configuration}) {
    configuration?.keys?.forEach((key) {
      if (!config.toMap().keys.contains(key)) {
        throw Exception(
            '$key: unknown. Allowed keys: ${config.toMap().keys.toString()}');
      }
    });
    if (configuration != null) {
      config = AppConfig.fromMap(configuration);
    }
    _url = (config.useTSL ? 'https' : 'http') + '://' + config.serverAddress;
  }

  Future<ClientResponse> exists(String collection) async {
    final url = '$_url/admin/exists/${_camelCaseFirstLower(collection)}';
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return ClientResponse(HttpStatus.ok, body);
    }
    return ClientResponse(response.statusCode, response.body);
  }

  Future<ClientResponse> createIndex(
    String collection, {
    String name,
    Map<String, dynamic> keys,
    bool unique = false,
    Map<String, dynamic> partialFilterExpression,
  }) async {
    final url = '$_url/admin/createindex/${_camelCaseFirstLower(collection)}';
    final body = json.encode({
      'name': name,
      'keys': keys,
      'unique': unique,
      'partialFilterExpression': partialFilterExpression,
    });
    return Future.sync(() {
      return http
          .post(url, headers: headers, body: body)
          .then(
              (response) => ClientResponse(response.statusCode, response.body))
          .catchError((e) =>
              ClientResponse(HttpStatus.internalServerError, e.toString()));
    });
  }

  Future<void> drop(String collection) async {
    final url = '$_url/admin/drop//${_camelCaseFirstLower(collection)}';
    await http.post(url, headers: headers);
  }

  Future<int> count(String collection,
      {Map<String, dynamic> filters = const {}}) async {
    filters['$collection.count'] = true;
    final response =
        await find(_camelCaseFirstLower(collection), filters: filters);
    if (response.status != HttpStatus.ok) {
      return 0;
    }
    final int count = int.tryParse(response.body);
    return count;
  }

  Future<ClientResponse> allowModel(String model) async {
    final response = await http
        .post('$_url/allow/${_camelCaseFirstLower(model)}', headers: headers);
    return ClientResponse(HttpStatus.ok, response.body);
  }

  Future<ClientResponse> findOne(
    String collection,
    String key,
    dynamic value,
  ) async {
    return Future.sync(() {
      return http
          .get(
            '$_url/${_camelCaseFirstLower(collection)}?$key=${value.toString()}',
            headers: headers,
          )
          .then(
              (response) => ClientResponse(response.statusCode, response.body))
          .catchError((e) =>
              ClientResponse(HttpStatus.internalServerError, e.toString()));
    });
  }

  Future<ClientResponse> findById(String collection, dynamic id) async {
    final response = await http.get(
      '$_url/${_camelCaseFirstLower(collection)}/${id.toString()}',
      headers: headers,
    );
    return ClientResponse(response.statusCode, response.body);
  }

  String _valueToJSon(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value == List || value is Map) {
      return json.encode(value);
    }
    return value.toString();
  }

  /// Executes a query om [model] that returns documents
  /// after applying the filters in the parameter [filter].
  /// If omitted, returns all the documents from the model
  /// subject to [limit] number of documents, after skipping
  /// [skip] number of documents. As mongoclient operates through
  /// a stateless REST server a cursor can not be preserved between calls
  /// This may result in server delays if the collection is large.
  Future<ClientResponse> find(
    String collection, {
    Map<String, dynamic> filters,
    int limit,
    int skip,
  }) async {
    String url = '$_url/${_camelCaseFirstLower(collection)}';
    String params = '';

    if (filters != null && filters.isNotEmpty) {
      filters.forEach((key, value) {
        if (params.isEmpty) {
          params = '?$key=' + _valueToJSon(value);
        } else {
          params += '&$key=' + _valueToJSon(value);
        }
      });
    }
    if (limit != null) {
      params += params.isEmpty ? '?' : '&' + 'limit=${limit.toString()}';
    }
    if (skip != null) {
      params += params.isEmpty ? '?' : '&' + 'limit=${skip.toString()}';
    }

    final response = await http.get(
      '$url$params',
      headers: headers,
    );

    return ClientResponse(response.statusCode, response.body);
  }

  Future<ClientResponse> remove(
      String collection, Map<String, dynamic> filters) async {
    // Todo: implimint priviliege and role based delete
    String model = _camelCaseFirstLower(collection);
    if (model == 'user' && !auth['isAdmin']) {
      return ClientResponse(
          HttpStatus.unauthorized, 'User can only be removed by an admin');
    }
    String params = '';
    String url = '$_url/$model';

    if (filters != null && filters.isNotEmpty) {
      filters.forEach((key, value) {
        if (params.isEmpty) {
          params = '?$key=' + value?.toString() ?? '';
        } else {
          params += '&$key=' + value?.toString() ?? '';
        }
      });
    }
    var response = await http.get('$url/$params', headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final ids = List<String>.from(json.decode(response.body));
      List<Map<String, dynamic>> deletedIds = [];
      bool error = false;
      ids.forEach((id) async {
        response = await http.delete('$url/$id', headers: headers);
        deletedIds.add(
            {'status': response.statusCode, 'id': 'id', 'body': response.body});
        if (!error) {
          error = response.statusCode == HttpStatus.ok;
        }
      });
      return ClientResponse(
          error ? HttpStatus.notModified : HttpStatus.ok, deletedIds);
    } else
      return ClientResponse(response.statusCode, response.body);
  }

  Future<ClientResponse> save(
    String collection,
    Map<String, dynamic> document,
  ) async {
    try {
      if(document['_id'] == null) {
        return ClientResponse(HttpStatus.internalServerError, 'Document \'_id\' is required');
      }
      final body = json.encode(document);
      final response = await http.patch(
        '$_url/${_camelCaseFirstLower(collection)}/${document['_id']}',
        headers: headers,
        body: body,
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(response.body);
      }
      return ClientResponse(HttpStatus.ok, response.body);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ClientResponse> update(
    String collection,
    Map<String, dynamic> document, {
    bool upsert = false,
    bool multiUpdate = false,
  }) async {
    try {
      final body = json.encode(document);
      String url = '$_url/${_camelCaseFirstLower(collection)}';
      url = url +
          '?upsert=' +
          upsert.toString() +
          '&&multiupdate=' +
          multiUpdate.toString();
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(response.body);
      }
      return ClientResponse(HttpStatus.ok, response.body);
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ClientResponse> createDocuments(
    String collection,
    dynamic documents,
  ) async {
    return Future.sync(() {
      final body = json.encode(documents is List ? documents : [documents]);
      return http
          .post(
        '$_url/${_camelCaseFirstLower(collection)}',
        headers: headers,
        body: body,
      )
          .then((response) {
        return ClientResponse(response.statusCode, response.body);
      }).catchError((e) {
        return ClientResponse(HttpStatus.internalServerError, e.toString());
      });
    });
  }

  /// Authenticate
  /// use [AuthAction.signInWithPassword] to login
  /// use [AuthAction.signUpWithPassword] to register new user

  Future<ClientResponse> authenticate(
    String username,
    String password,
    AuthAction authAction,
  ) async {
    final creds = json.encode({
      'username': username,
      'password': password,
      // 'isAdmin': false, // can be set to true only by another admin
    });

    if (authAction == AuthAction.signUpWithPassword) {
      //  Register new user
      return Future.sync(() {
        return http
            .post(
          '$_url/register',
          headers: headers,
          body: creds,
        )
            .then((response) {
          return ClientResponse(response.statusCode, response.body);
        }).catchError((e) {
          return ClientResponse(HttpStatus.internalServerError, e.toString());
        });
      });
    }
    return Future.sync(() {
      return http
          .post(
        '$_url/auth/token',
        headers: headers,
        body: creds,
      )
          .then((response) {
        if (response.statusCode != HttpStatus.ok) {
          return ClientResponse(response.statusCode, response.body);
        }
        final body = json.decode(response.body);
        auth = body['user'];
        headers['Authorization'] = 'Bearer ${body['token']}';

        return ClientResponse(response.statusCode, {
          'status': 'ok',
          'expiry': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
          'user': body['user'],
          'access-token': body['token'],
        });
      }).catchError((e) {
        return ClientResponse(HttpStatus.internalServerError, e.toString());
      });
    });
  }
}

enum AuthAction {
  signInWithPassword,
  signUpWithPassword,
  signOut,
}

class ClientResponse {
  final int status;
  final dynamic _body;
  ClientResponse(this.status, dynamic body) : _body = json.encode(body ?? {});
  int get statusCode => status;
  dynamic get body => json.decode(_body);
}

String _camelCase(String text) {
  String capitalize(Match m) =>
      m[0].substring(0, 1).toUpperCase() + m[0].substring(1);
  String skip(String s) => "";
  return text.splitMapJoin(new RegExp(r'[a-zA-Z0-9]+'),
      onMatch: capitalize, onNonMatch: skip);
}

/*
String _snakeCase(String text) {
  var tl = '';
  _camelCaseFirstLower(text).split('').forEach(
      (c) => tl += RegExp(r'[A-Z]').hasMatch(c) ? '_' + c.toLowerCase() : c);
  return tl;
}
*/

String _camelCaseFirstLower(String text) {
  final camelCaseText = _camelCase(text);
  final firstChar = camelCaseText.substring(0, 1).toLowerCase();
  final rest = camelCaseText.substring(1);
  return '$firstChar$rest';
}
