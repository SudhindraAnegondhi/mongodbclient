import 'dart:convert';
import 'dart:io';
import 'app_configuration.dart';
import 'package:http/http.dart';



class MongoDbClient {
  AppConfig config = AppConfig();
  String _url;
  final headers = {'content-type': 'Application/json'};

  MongoDbClient({Map<String, dynamic> configuration}) {
    try {
      if (configuration != null) {
        configuration.keys.forEach((key) {
          if (!config.toMap().keys.contains(key)) {
            throw Exception(
                '$key: unknown. Allowed keys: ${config.toMap().keys.toString()}');
          }
        });
        config = AppConfig.fromMap(configuration);
      }

      _url = (config.useSSL ? 'https' : 'http') + '://' + config.serverAddress;
    } catch (e) {
      throw Exception('Config error');
    }
  }
  Future<ClientResponse> allowModel(String model) async {
    final response = await post(
      '$_url/allow/$model',
      headers: headers,
    );

    return ClientResponse(HttpStatus.ok, response.body);
  }

  Future<ClientResponse> findOne()

  Future<ClientResponse> createDocument(
    String collection,
    Map<String, dynamic> document,
  ) async {
    try {
      final body = json.encode(document);
      final response = await post(
        '$_url/$collection',
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

  Future<Map<String, dynamic>> authenticate(
    String username,
    String password,
    AuthAction authAction,
  ) async {
    final creds = json.encode({
      'username': username,
      'password': password,
    });
    Response response;
    if (authAction == AuthAction.signUpWithPassword) {
      response = await post('$_url/register', headers: headers, body: creds);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(response.body);
      }
      response = await post('$_url/auth_token', headers: headers, body: creds);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Please login again');
      }
      final body = json.decode(response.body);
      headers['Authorization'] = 'Bearer ${body['token']}';
      return {
        'status': 'ok',
        'expiry': DateTime.now().add(Duration(hours: 24)),
        'user': body['user']
      };
    }

    /// sign in
    response = await post('$_url/auth/token', headers: headers, body: creds);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(response.body);
    }
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Please login again');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    headers['Authorization'] = 'Bearer ${body['token']}';
    return {
      'status': 'ok',
      'expiry': DateTime.now().add(Duration(hours: 24)),
      'user': body['user']
    };
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
