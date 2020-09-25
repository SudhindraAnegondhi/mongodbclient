import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:mongoclient/mongoclient.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  final db = MongoDbClient();
  parser.addOption('user', abbr: 'u', help: 'username:password');
  parser.addOption('values', abbr: 'v', help: '[<colA>...]');
  parser.addFlag('register', abbr: 'r', help: 'register new user');
  parser.addOption('mode',
      abbr: 'm',
      allowed: [
        'list',
        'l',
        'find',
        'f',
        'add',
        'a',
        'update',
        'u',
        'search',
        's',
      ],
      defaultsTo: 'l',
      help: 'Mode: ',
      allowedHelp: {
        'a': 'add',
        'f': 'find',
        'l': 'list',
        's': 'search',
        'u': 'update',
      });
  parser.addOption(
    'id',
    abbr: 'i',
    help: 'Required with find or update mode.',
  );
  parser.addOption(
    'data',
    abbr: 'd',
    help:
        'Json string. Required with add,search, update  and value modes. Specify fields with values to be updated or added or searched. List map of name, values ',
  );
  parser.addOption(
    'table',
    abbr: 't',
    help: 'Table name to be used',
  );
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Print this usage information.',
  );

  final results = parser.parse(args);
  if (results['help']) {
    print(parser.usage);
    exit(0);
  }
  Map<String, dynamic> creds;
  if (results['user'] != null) {
    final userpass = results['user'].split(':');
    if (userpass.length != 2) {
      print('Register failed. username and password required, Seprated by :.');
      exit(1);
    }
    if (results['register']) {
      await register(db, userpass[0], userpass[1]);
      exit(0);
    }
    creds = await authenticate(db, userpass[0], userpass[1]);
    if (creds['error'] != null) {
      print(creds['error']);
      exit(1);
    }
  }
  if (results['user'] != null) {
    final userpass = results['user'].split(':');
    if (userpass.length != 2) {
      print(' username and password required, Seprated by :.');
      exit(1);
    }
  }
  if (results['table'] == null && results['register'] == null) {
    print('please specify a table name with -t or --table');
    exit(1);
  }
  final String opCode = results['mode'][0].toLowerCase();
  if ('asuv'.contains(opCode) && results['data'] == null) {
    print(
        'You must provide data json string to add, search, update or limit values');
    exit(1);
  }
  if ((opCode == 'u' || opCode == 'f') && results['id'] == null) {
    print('You must provide record ID to find or update');
    exit(1);
  }
  final List names = json.decode(results['values'] ?? '[]');
  final response = await query(
    db,
    opCode,
    results['table'],
    results['id'],
    results['data'],
    creds['access_token'],
  );
  if (names.isEmpty) {
    print(response.toString() ?? 'No result');
  } else {
    response.forEach((element) {
      // ignore: omit_local_variable_types
      Map<String, dynamic> printable = {};
      names.forEach((name) {
        if (element.containsKey(name)) {
          printable[name] = element[name];
        } else {
          print('$name is not a valid column name');
          names.removeWhere((n) => n == name);
        }
      });
      print(printable.toString().replaceAll('{', '').replaceAll('}', ''));
    });
  }
}

Future<List<dynamic>> query(
  MongoDbClient db,
  String opCode,
  String table,
  String id,
  String data,
  String accessToken,
) async {
  Map<String, dynamic> response;
  
  try {
    switch (opCode) {
      case 'a':
        ClientResponse response = await db.createDocument(
          table,
          json.decode(data),
        );

        if (response.statusCode == 200) {
          return [response.body];
        }
        break;
      /*
      case 's':
        response = await http.get(
          '$url/$table?filter=$data',
          headers: headers,
        );
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
        break;
      case 'u':
        response = await http.put(
          '$url/$table/$id',
          headers: headers,
          body: json.encode(data),
        );
        if (response.statusCode == 200) {
          return [json.decode(response.body)];
        }
        break;
      case 'l':
        response = await http.get(
          '$url/$table',
          headers: headers,
        );
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
        break;
      case 'f':
        response = await http.get(
          '$url/$table/$id',
          headers: headers,
        );
        if (response.statusCode == 200) {
          return [json.decode(response.body)];
        }
        break;
        */
    }
  } catch (e) {
    print('$opCode on $table with $data failed\nReason: ${e.toString()}');
  }
  print('$opCode on $table with $data failed\nReason: ${response.toString()}');
  return null;
}

Future<Map<String, dynamic>> authenticate(
  MongoDbClient db,
  String username,
  String password,
) async {
  try {
    final creds = await db.authenticate(
        username, password, AuthAction.signInWithPassword);
    print(creds.toString());
    return creds;
  } on HttpException catch (e) {
    return {'error': e.message};
  }
}

Future<void> register(
  MongoDbClient db,
  String username,
  String password,
) async {
  try {
    return await db.authenticate(
      username,
      password,
      AuthAction.signUpWithPassword,
    );
  } on HttpException catch (e) {
    return {'error': e.message};
  }
}
