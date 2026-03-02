class Asset {
  final String id;
  final String assetCode;
  final String name;
  final String? brand;
  final String? specification;
  final String? mainClass;
  final String? midClass;
  final String? year;
  final String? batch;
  final double? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final String? userDept;
  final String? custodian;
  final String? location;
  final DateTime? purchaseDate;
  final DateTime? warrantyDate;
  final String? usefulLife;
  final String? status;
  final String? remark;
  final String? fileDescription;
  final List<AssetImage> images;

  Asset({
    required this.id,
    required this.assetCode,
    required this.name,
    this.brand,
    this.specification,
    this.mainClass,
    this.midClass,
    this.year,
    this.batch,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.userDept,
    this.custodian,
    this.location,
    this.purchaseDate,
    this.warrantyDate,
    this.usefulLife,
    this.status,
    this.remark,
    this.fileDescription,
    this.images = const [],
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] ?? '',
      assetCode: json['assetCode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'],
      specification: json['specification'],
      mainClass: json['mainClass'],
      midClass: json['midClass'],
      year: json['year'],
      batch: json['batch'],
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      unitPrice: json['unitPrice'] != null
          ? (json['unitPrice'] as num).toDouble()
          : null,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
      userDept: json['userDept'],
      custodian: json['custodian'],
      location: json['location'],
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : null,
      warrantyDate: json['warrantyDate'] != null
          ? DateTime.parse(json['warrantyDate'])
          : null,
      usefulLife: json['usefulLife'],
      status: json['status'],
      remark: json['remark'],
      fileDescription: json['fileDescription'],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => AssetImage.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetCode': assetCode,
      'name': name,
      'brand': brand,
      'specification': specification,
      'mainClass': mainClass,
      'midClass': midClass,
      'year': year,
      'batch': batch,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'userDept': userDept,
      'custodian': custodian,
      'location': location,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'warrantyDate': warrantyDate?.toIso8601String(),
      'usefulLife': usefulLife,
      'status': status,
      'remark': remark,
      'fileDescription': fileDescription,
    };
  }
}

class AssetImage {
  final String id;
  final String fileName;
  final String url;

  AssetImage({required this.id, required this.fileName, required this.url});

  factory AssetImage.fromJson(Map<String, dynamic> json) {
    return AssetImage(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName'] ?? '',
      url: json['url'] ?? '/api/files/download/${json['fileName']}',
    );
  }
}
