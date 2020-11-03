# MongoDb Dart Client Library

A library to connect to **MongoDb Server**. The libaray  provides a single class `MongoClient`. The client library is written in pure Dart and may be used with bothh Dart and Flutter.

## Usage

A simple usage example:

```dart
import 'package:mongoclient/mongoclient.dart';

main() {
  final MongoDbClient db = MongoDbClient(configuration: {
    "serverAddress": "localhost:8888",
    "authSecret": "mySecret",
    "useTSL": false,
  });
}
```

### Configuration

The `serverAddress` is the address  and port where  `mongoserver` is running. `authSecret` is the shared secret between the server and client and can be any 24 character string. If the server uses TSL (Transport Security Layer), set `useTSL` to `true`.

The configuration argument is optional. If no configuration is provided, MongoClient uses localhost as the address, 8888 as the port, a program specified authSecret and useTSL is set to false.

## Client API calls

### Response from the Client

All calls to the Client return a ClientResponse object, containing the response status code and data or message returned from the client.

```dart
class ClientResponse {
  final int status;
  final dynamic body;
}

```

The status returned is ```HttpStatus```
The body can contain either a String message or a document object - either List<Map<String, dynamic>> or a Map<String, dynamic> for calls that return a single document.

### Adding Users and authenticating users

The server allows access only to authenticated users. Users may be added through  the authenticate API call by
calling API with AuthAction.signUpWithPassword flag. Existing users are authenticated by the authenticate call with AuthAction,signInWithPassword option.

```Map<String, dynamic> response```: ```"status"```: HttpStatus.ok, ```"user"```: Map<String, dynamic> user if the call was successful else a **HttpException** is thrown
with the cause as a String in the body.

```dart
// Sign up new user
final Map<String, dynamic> response = await db.authenticate(
  username,
   password,
   AuthAction.signUpWithPassword,
);

// Sign in existing user
final Map<String, dynamic> response = await db.authenticate(
  username,
   password,
   AuthAction.signUInWithPassword,
);

```

### **Alow temporary access to a Model**

The server allows access only to models that are either included in the server's model directory
or registered by adding the model name to the list in server's ```config.yaml``` file.

The client, however, may request *temporary* registration of a model. This registration request is accepted
*only from an admin user*. This registration is not permanent and is lost if the server is restarted. Once
the model is registered, normal users without admin privileges are granted access normally.

Responses may be: **HttpStatus.ok** - Registration granted, HttpStatus.ok - Model is already registered or
**HttpStatus.unauthorized** - If the logged in user is not an admin.

```dart

final ClientResponse response = db.allowModel('foo);

```

### **Find a document by a unique field**

Models part of the server allow retrieving documents by their primary keys. Please note that  **mongoDb**'s
requirement that document ID must be length limited, the server does not allow document IDs to be primary keys.
If the model is integrated with the server (as opposed to merely being registered), the user may
specify any field as primary key. The search key can be any field of course. Primary keys are used to ensure
the uniqueness of a document within the collection and are of course retrieved faster.

Response: If successful, Status: HttpStatus.Ok, body: Map<String, dynamic> document.
On failure, status: HttpStatus corresponding to error for failure, body: String error desciption.

```dart
String collectionName = "widgets";
String key= "productId";
int productId = 4537865690; // can be any scalar unique value
final ClientResponse response =await db.findOne(collectionName,
key,
productId
);
```

#### **Find a document by its Id**

**MongoDb** inserts a field '_id' with an unuque *ObjectId* when the document is inserted. The document can
be retrieved using it's *_id* field.

Response: If successful, Status: HttpStatus.Ok, body: Map<String, dynamic> document.
On failure, status: HttpStatus corresponding to error for failure, body: String error desciption.

```dart
final ClientResponse response =await db.findOne(collectionName,
  document['_id'],
);
```

#### **Get multiple documents**

Getting all documents is simple.

```dart
final ClientResponse response =await db.find(collectionName);
```

This will retrieve *all* documents in the collection. The retrieval does not guarantee any order.

Filters can be used to

- Get all document meeting one or more criteria.
- Limit the number of documents retrieved

Response if successful, one or more documents that met the search parameters.

```dart
final ClientResponse response =await db.find(collectionName,
filters: filters);

```

##### **Filters**

Filters are used to: a) Search for documents meeting specific conditions, b) Sort the documents.

For example retrieve all products with at least 10 orders or discount of less than 30% and out of stock,
and  sorted by leadTime joined with suppliers for the product with rating greater than 5:

```dart
Map<String, dynamic> filters = {
  "orders.gte": 10,
  "or": null,
  "discount.lt": 0.30,
  "stockQuantity": 0,
  "join" {
    "collectionName": "suppliers",
    "where":[
      // parent collection to child collection comparisions
      { "parentField": "supplierId.eq", "childField": "_id" },
      // child collection fields
      { "rating.gt": 5 },
    ]
  },
  "sortBy": "leadTime.desc"
}

```

## Database Structure and Maintenance

For trivial applications, registering the name of a model - or as termed by MongoDb, a collection, is
sufficient for the application to create, read, update and delete documents. As the server lacks any
knowledge of the model's structure, it performs no validations regarding the operations. Thus the
application may change the structure, type of fields etc in each insert/update operation. Of course,
this freedom can lead to bugs in the application data by a badly written application. Further, as the
server has no knowledge of the model's primary key, duplicate records can freely be added. Queries
can fail due to badly spelt field names, types or collection names. All database maintenance operations
require admin privileges. This is done using ```monoadmin``` command.

### Adding Collection to the server

A new Collection can be added to the server by the user. The server adds the collection to it's permanent code
and restarts to integrate the collection (Model). This is done in two steps.

#### Step 1: Validate and Edit new collection class

Create a json data model of the new collection, with typical data entered against each field. Primary key, foreign key index and noUpdate entries are optional. The
no update list controls which fields may be updated through an update.

Example:

```sh
$ cat newmodel.json
{
  "collectionName": "SpecialWidgets",
  "primary key": "widgetname",
  "foreign keys": [
    {"product_id": "products"},
    {"supplier_id": "supplier"};
  ],
  "index": ["product_id", "supplier_id"],
  "noUpdate": ["widgetname", "product_id". "supplier_id"],
  "dateFields"["lastUsed"],
  "fields": {
    "widgetName": "xxx xx",
    "product_id": "addfdf12",
    "supplier_id": "adnfdfd",
    "description": "xxxx",
    "assemblyCode": "adfdfdfd",
    "quuantityInStock": 24,
    "quantityOnOrder": 200,
    "price": 2987.56,
    "lastUsed": "2020-11-21T12:45.012.782Z",
    "models": ["xxx", "dfdfd", "cccc"],
    "hasSubstitutes": false,
    "bomLink": "https://bom.acme.dfut/xxx%20xx"
  }
}
$ mongoadmin validate newmodel.json
Mongo Admin version 0.0.1

JSON has errors

Error: Parse error on line 9:
..._id": "supplier"  }; ], "index": ["pr
----------------------^
Expecting 'EOF', '}', ',', ']', got 'undefined'

Please fix the error(s) and revalidate
```

As the validator emits error at the first error encountered, you will have to iteratively correct the JSON file until the validator reports ```Valid JSON```.

#### Step - 2: Add Model to server

```sh
$ mongoadmin  addmodel newmodel.json
Mango Admin version 0.0.1
Enter username: admino
Enter password: **********
Adding model [SpecialWidget] to schemas....done
Adding route [/specialwidget and /specialwidget/<id>] to service.....done
restarting mongoserver........done
$
```

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

## Credits

JSON to Dart class generation is thanks to [Javier Lecuona](https://github.com/javiercbk/json_to_dart), most of that code is used as is except to add *mongoserver* specific getters.

## License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
