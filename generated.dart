class SpecialWidgets {
  // camel case classname first letter to uppercase

  String widgetName;
  String productId;
  String supplierId;
  String description;
  String assemblyCode;
  int quantityInStock;
  int quantityOnOrder;
  double price;
  String lastUsed; // change "dateField" to DateTime
  List<String> models;
  bool hasSubstitutes;
  String bomLink;

// Add these
  String get PrimaryKey => "widgetName";
  String get className => "SpecialWidgets";
  // only bools, dates need to be added
  Map<String, String> get typeMap =>
      {"lastUsed": "DateTime", "hasSubstitute": "bool"};
  List<Map<String, String>> get foreignKeys => [
        {"product_id": "products"},
        {"supplier_id": "supplier"},
      ];
  List<String> get index => [
        "widgetName",
        "product_id",
        "supplier_id",
      ];
  SpecialWidgets(
      {this.widgetName,
      this.productId,
      this.supplierId,
      this.description,
      this.assemblyCode,
      this.quantityInStock,
      this.quantityOnOrder,
      this.price,
      this.lastUsed,
      this.models,
      this.hasSubstitutes,
      this.bomLink});

  SpecialWidgets.fromJson(Map<String, dynamic> json) {
    widgetName = json['widgetName'];
    productId = json['product_id'];
    supplierId = json['supplier_id'];
    description = json['description'];
    assemblyCode = json['assemblyCode'];
    quantityInStock = json['quantityInStock'];
    quantityOnOrder = json['quantityOnOrder'];
    price = json['price'];
    lastUsed = json['lastUsed']; // Change dateField -> DateTime.parse(json)
    models = json['models'].cast<String>();
    hasSubstitutes = json['hasSubstitutes'];
    bomLink = json['bomLink'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['widgetName'] = this.widgetName;
    data['product_id'] = this.productId;
    data['supplier_id'] = this.supplierId;
    data['description'] = this.description;
    data['assemblyCode'] = this.assemblyCode;
    data['quantityInStock'] = this.quantityInStock;
    data['quantityOnOrder'] = this.quantityOnOrder;
    data['price'] = this.price;
    data['lastUsed'] = this.lastUsed;
    data['models'] = this.models;
    data['hasSubstitutes'] = this.hasSubstitutes;
    data['bomLink'] = this.bomLink;
    return data;
  }
}
