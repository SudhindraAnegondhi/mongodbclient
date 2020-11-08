<!-- omit in toc -->
# MongoDb Dart Client Library

<img src="readme/dart-logo-png-transparent.png" width="15"> **Dart** <img src="readme/flutter-logo.svg" width="15"> **Flutter** <img src="readme/macos-apple-logi.png" width="18"> **macOS** <img src="readme/linux-logo.jpg" width="15"> **Linux** <img src="readme/iphone-logo.png" width="15"> **iOS** <img src="readme/android.jpg" width="18"> **android** <img src="readme/web.jpg" width="18"> **Web**

A Client library to connect to **MongoDb Server**. The libaray  provides a single class **`MongoDbClient`**. The client library is written in pure Dart and may be used with Dart and Flutter on any platform (Not tested on Windows).

- [Library Functions](#library-functions)
  - [allowModel(String model) -> Future\<ClientResponse>](#allowmodelstring-model---futureclientresponse)
  - [authenticate(String username, String password, AuthAction action)](#authenticatestring-username-string-password-authaction-action)
  - [count(String collection, {Map<String, dynamic> filters}) -> Future\<int>](#countstring-collection-mapstring-dynamic-filters---futureint)
  - [createDocuments(String collection, dynamic documents)](#createdocumentsstring-collection-dynamic-documents)
  - [Insert a single document](#insert-a-single-document)
    - [Primary keys](#primary-keys)
  - [Inserting multiple documents](#inserting-multiple-documents)
  - [createIndex(String collection, {String name, Map<String, dynamic> keys, bool unique, Map<String, dynamic> partialFilterExpression})](#createindexstring-collection-string-name-mapstring-dynamic-keys-bool-unique-mapstring-dynamic-partialfilterexpression)
    - [Index name](#index-name)
    - [Index keys](#index-keys)
    - [Unique](#unique)
    - [Partial Indexes](#partial-indexes)
  - [drop(String model)](#dropstring-model)
  - [exists(String model)](#existsstring-model)
  - [find(String collection, Map<String, dynamic> filters, {int limit, int skip})](#findstring-collection-mapstring-dynamic-filters-int-limit-int-skip)
    - [Simple filter](#simple-filter)
    - [Filter Opcodes & Multiple conditions](#filter-opcodes--multiple-conditions)
    - [List of Opcodes](#list-of-opcodes)
  - [findById(String collection, dynamic id)](#findbyidstring-collection-dynamic-id)
  - [findOne(String collection, String key, dynamic value)](#findonestring-collection-string-key-dynamic-value)
  - [remove(String collection, Map<String, dynamic> filters)](#removestring-collection-mapstring-dynamic-filters)
  - [save(String collection, Map<String, document> document)](#savestring-collection-mapstring-document-document)
  - [update(String collection, Map<String, dynamic> document, {bool upsert, bool multiUpdate})](#updatestring-collection-mapstring-dynamic-document-bool-upsert-bool-multiupdate)
- [Issues](#issues)
- [License](#license)

## Library Functions

**All Functions return `Future<ClientResponse>`.**

`ClientResponse.status` is same as `HttpStatus` (200 is Ok, etc). `ClientResponse.body` contains data returned from the server.

```dart
class ClientResponse {
  final int _status;
  final dynamic _body;

  ClientResponse(int status, dynamic body)
    :_status = status, _body = json.encode(body ?? {});

  int get statusCode => _status;
  dynamic get body => json.decode(_body);
}
```

### allowModel(String model) -> Future\<ClientResponse>

Normally,  server will only accept requests that affect models registered with
the server. Models can be registered using **mongoadmin**. This requires
stopping the server, running mongoadmin, adding model and restarting the server.

If the model usage is of a temporary nature, this function can be used to inform
the server to accept the model temporarily. **Please note:** Models allowed using
*allowModel* function are volatile and do not survive a server restart.

Returns status 200 if the model was allowed. User requires no spcial privileges
for this function.

### authenticate(String username, String password, AuthAction action)

This function can be used to register or *signup* ordinary users, using
 `AuthAction.signUpWithPassword` action *signIn* with `AuthAction.signUpWithPassword`.

```dart
enum AuthAction {
  signInWithPassword,
  signUpWithPassword,
}
```

***Please Note***

- A new Username *must* be an email address.
  
- Password must at least be 8 characters long and must contain at least one of
 each of the following:
  
  - Uppercase letter
  - Lowercase letter
  - Digit
  - Special Character - One of # ! @ $ %

Returns status 200 if the operation succeeded.

On succesful log on,  `Response.body` contains the following map:

```dart
{
  'status': 'ok',
  'expiry': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
  'user': {
      'username': username,
      'hashedPassword': hashedPassword,
      'salt': salt,
      'isAdmin': isAdmin,
    },
  'access-token': authorizationToken,
}
```

### count(String collection, {Map<String, dynamic> filters}) -> Future\<int>

***Important***:  *Returns int and not `ClientResponse`*.

Returns the number of documents matching the filters. If no filters
are specified, the number of documents contained in the collection
is returned. **Please note:** *This isthe only function that does not
return a `ClientResponse`, at this time.

```dart
import 'packages:mongoclient/mongoclient.dart'

...
final db = MongoDbClient();

final int count = await db.count('products');

```

### createDocuments(String collection, dynamic documents)

Inserts one or more documents in the collection.

Validation of the document regarding the names and types of the fields
is done differently for a registered model and a temporarily allowed
model.

All inserts/updates to registered models are validated for field names
and types. A new document must contain the same number, names and types
of the schema fields. A document being updated may only contain fields
in the schema.

No schema validation takes place for inserts to a temporarily allowed
model beyond checking where possible that the schema of previously
inserted documents match the new document.

**To be implemented**: Validation business rules.

### Insert a single document

```dart
import 'packages:mongoclient/mongoclient.dart'

...
final db = MongoDbClient();

// Single document insert
final Map<String, dynamic> document = {
  "productName": "Widget",
  "productNumber": "WD045-45565-787",
  "ItemQuantity": 345,
  "reOrderQuantity": 500,
};

final ClientResponse response = await db.createDocuments('products', document);
```

#### Primary keys

MongoClient returns the newly created document along with the **\_id** field containing
the document id generated by mongoDb upon insertion. The id is a 24 character hexadecimal
string. If the document  property contains an **\_id** field, *mongoDB will attempt to update
the document and not create it.*

### Inserting multiple documents

```dart
import 'packages:mongoclient/mongoclient.dart'

...
final db = MongoDbClient();

// documents is a List<Map<String, dynamic>> object

final ClientResponse response = await db.createDocuments('transactions', documents);
print('Wrote ${response.body['count'].toString} transactions);
```

Inserting mutliple documents returns the number inserted.

### createIndex(String collection, {String name, Map<String, dynamic> keys, bool unique, Map<String, dynamic> partialFilterExpression})

MongoDB creates a unique index on the \_id field during the creation of a collection. The \_id index prevents clients from inserting two documents with the same value for the \_id field. You cannot drop this index on the \_id field.

#### Index name

The default name for an index is the concatenation of the indexed keys and each key’s direction in the index ( i.e. 1 or -1) using underscores as a separator. For example, an index created on `{ item : 1, quantity: -1 }` has the name **item_1_quantity_-1**.

By specififying *name*, a custom human readable index name can be created. This must be unique.

#### Index keys

Index can be either simple or compound. The *keys* property for defining simple index, for example: `{'email': -1}` sorts documents in descending order on `email`. The *keys* property for  a compound index, for example: `{'date': -1, 'customerName': 1}` causes documents to be first sorted on `date` in descending order and within the date by `customerName` in ascending order.

#### Unique

The *unique* property for an index causes MongoDB to reject duplicate values for the indexed field. Other than the unique constraint, unique indexes are functionally interchangeable with other MongoDB indexes.

#### Partial Indexes

Partial indexes only index the documents in a collection that meet a specified filter expression set by the *partialFilterExpression*. By indexing a subset of the documents in a collection, partial indexes have lower storage requirements and reduced performance costs for index creation and maintenance.

```dart
import 'package:mongoclient/mongoclient.dart';

...

final db = MongoDbClient();

final response = db.createIndex(
  'products',
  keys: {'productName': 1},
  unique: true);
```

### drop(String model)

The drop function removes an entire collection from a database.

```dart
import 'package:mongoclient/mongoclient.dart';

...

final db = MongoDbClient();

final response = db.drop('test');
```

### exists(String model)

Returns `{'exists': true}` if the collection exists in the database.

```dart
import 'package:mongoclient/mongoclient.dart';
...
final db = MongoDbClient();

final response = db.exists('test');

if(response.status == 200 && response.body['exists']) {
  print('$model exists);
}
```

### find(String collection, Map<String, dynamic> filters, {int limit, int skip})

Executes a server query on the collection, returns documents based on the query
parameters specified through filter.

#### Simple filter

```dart
import 'package:mongoclient/mongoclient.dart';
...
final db = MongoDbClient();
final response = db.find('customer', filters={'name': 'XYZ Co'} );
if(response.status == 200){
  final customer = Customer.fromMap(response.body[0]);
  print('${customer.name}\t${customer.email}`);
}
```

#### Filter Opcodes & Multiple conditions

The simple filter used above is intrepreted as `customer.where(name == 'XYZ.Co')`, because
as there is no opcode specified `mongoDbClient` assumes opcode **equals**.

Opcodes are separated from field name with a **:**. If we wanted say all customers with
balanceDue > 50,000, the filter would be `{'balanceDue.gt': 50000}.

#### List of Opcodes

- **all**: Documents containing any of the values in the list. For example: `{'ranks:all': ['Captain', 'Major','Lieut.Colonel']}`
- **and**: Logical `AND`. Default combining operation. All preceding filters are treated as a group and all subsequent filters as the second and GRP1 AND GRP2 is generated. `{'and': true}`.
- **comment:** Inserts a comment at that point in the query build object.
- **eq**: `Equals`.Default Opcode. Omission of opcode from a filter expression implies `Equals`.
- **excludeFields**: Excludes the fields in the list from the projection. For example: `{'excludeFields', ['creationDate', 'updateDate']}`.
- **exists**: Tests the existence of a field without testing it's value. The query succeeds if the field exists. Useful for dynamic schema contents. Eg., `{'exists': 'somefield`}.
- **fields**: If present only fields in the list specified will be returned in the projection.
- **gt**:  `GreaterThan` or `>`.
- **gte**:  `GreaterThanOrEquals` or `>=`.
- **hintIndex**: Suggest using a specific index for this query. `{'product_-1': true}`.
- **id**: The `ObjectId` of the document. `{'id': _id.toHexString())`.
- **inRange**: True if field value falls in the range. `{'price:inRange': {'min': 200, 'max': 300, 'mininclude': false, 'maxinclude': false}}`.
- **jsQuery**: jQuery Javascript expression. `{'jsQuery': 'jsExpression'}`.
- **limit**:  Limit the number of documents returned by the query. `{'limit`: 30}`.
- **lt**: `LessThan`. `{'age:lt': 56}`.
- **lte**: `LessThanOrEquals`. `{'age:lte': 56}`.
- **match**: Regular Expression match. `{'address': {'match': r'^\s+(\w+)-45\,.*\$', 'multiline': false, 'caseInsensitive': false, 'dotAll': false, 'extended': false}}`.  
<!--- mod: expect fieldname, int -> sb -->
- **ne**: `NotEquals` or `!=`. `{'post:ne': 'supervisor'}`.
- **near**: Fuzzy equals or *near* the value and within the optional distance specified. `{'age:near': {'value': 20, 'distance': 1.0}`.
- **nin**: `NotIn`. Document value *not in* the list specified. `{'age.nin': [17,19, 32]}`.
- **notExists**:  Tests the non existence of a field without testing it's value. The query succeeds if the field does not exist. Useful for dynamic schema contents. Eg., `{'notExists': 'timeInGrade`}.
- **oneFrom**: Document value *one from* the list specified. `{'age.oneFrom': [17,19, 32]}`.
- **or**: Logical `OR`. All preceding filters are treated as a group and all subsequent filters as the second and GRP1 OR GRP2 is generated. `{'or': true}`.
- **skip**: Skip `skip` number of documents in the generated query. `{'skip': 100`
- **sortBy**: Sort key to sort the documents. Sorting occurs in the order listed. `{'date': -1}`.

### findById(String collection, dynamic id)

Retrieves the document by id. When mongodb inserts a record it assigns an unique `ObjectId` to the document.

`id` property can either be an `ObjectId` object or an  HexString (max 24 characters), which
can be converted to an `objectId`.

```dart
import 'package:mongoclient/mongoclient.dart';
...
final db = MongoDbClient();
 ...
// String id contains HexString
final response = db.findById('customer', ObjectId.fromHexString(id) );
if(response.status == 200){
  final customer = Customer.fromMap(response.body[0]);
  print('${customer.name}\t${customer.email}`);
}
```

### findOne(String collection, String key, dynamic value)

Returns a single document whose *key* is equal to *value* supplied.

```dart
import 'package:mongoclient/mongoclient.dart';
...
final db = MongoDbClient();
 ...
// String id contains HexString
final response = db.findOne('customer', 'name', 'XYZ Co.Ltd' );
if(response.status == 200){
  final customer = Customer.fromMap(response.body[0]);
  print('${customer.name}\t${customer.email}`);
}
```

### remove(String collection, Map<String, dynamic> filters)

Removes all documents meeting the filters parameter. Empty filters parameter has no effect.

Returns a non Ok status if the documents can not be found. If all the documents are found, returns a List<Map<String, dynamic>>{'status': x, 'id': 'id', 'remarks': 'xx'}.

### save(String collection, Map<String, document> document)

Save can modify all or some fields of a document. The `document` must have a valid `_id`
element.

```dart
import 'package:mongoclient/mongoclient.dart';
...
final db = MongoDbClient();
 ...
// String id contains HexString
var response = db.findOne('customer', 'name', 'XYZ Co.Ltd' );
if(response.status != 200){
  return;
final customer = Customer.fromMap(response.body[0]);
customer.balance += 1000;
var response = db.save('customer', customer.toMap());
```

### update(String collection, Map<String, dynamic> document, {bool upsert, bool multiUpdate})

This function is similar to `update()` function above in that it attempts to update the document. If the document does not exist and  `upsert` is `true`, inserts the document. This must be a complete record.

```dart
import 'package:mongoclient/mongoclient.dart';
...
final db = MongoDbClient();
 ...
// String id contains HexString
var response = db.findOne('customer', 'name', 'XYZ Co.Ltd' );
if(response.status != 200){
  return;
final customer = Customer.fromMap(response.body[0]);
customer.balance += 1000;
var response = db.update('customer', customer.toMap(), upsert: false);
```

______________________________

## Issues

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

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
