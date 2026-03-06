import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide AssetImage;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../models/asset_model.dart';

class FormDropdownItem {
  final String value;
  final String label;
  FormDropdownItem({required this.value, required this.label});
}

class AssetFormPage extends StatefulWidget {
  final Asset? asset;

  const AssetFormPage({super.key, this.asset});

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _assetCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _specController = TextEditingController();
  final _quantityController = TextEditingController();
  final _remarkController = TextEditingController();
  final _batchController = TextEditingController(text: '001');

  // 新增欄位 Controllers
  final _purchaseDateController = TextEditingController();
  final _warrantyDateController = TextEditingController();
  final _unitPriceController = TextEditingController(text: '0');
  final _unitController = TextEditingController();

  String? _status;
  String? _classType;
  String? _regionId;

  // Dropdown items
  List<FormDropdownItem> _mainClasses = [];
  List<FormDropdownItem> _midClasses = [];
  List<FormDropdownItem> _filteredMidClasses = [];
  final List<FormDropdownItem> _years = List.generate(
    20,
    (index) => FormDropdownItem(
      value: (100 + index).toString(),
      label: (100 + index).toString(),
    ),
  );
  List<FormDropdownItem> _custodians = [];
  List<FormDropdownItem> _locations = [];
  List<FormDropdownItem> _useTypes = [];
  List<FormDropdownItem> _classTypes = [];
  List<FormDropdownItem> _regions = [];
  List<FormDropdownItem> _filteredRegions = [];

  String? _mainClass;
  String? _midClass;
  String? _year;
  String? _custodian;
  String? _location;

  final List<XFile> _selectedImages = [];
  List<AssetImage> _existingImages = [];
  final List<String> _deletedImageIds = [];
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _assetCodeController.text = widget.asset!.assetCode;
      _nameController.text = widget.asset!.name;
      _brandController.text = widget.asset!.brand ?? '';
      _specController.text = widget.asset!.specification ?? '';
      _mainClass = widget.asset!.mainClass;
      _midClass = widget.asset!.midClass;
      _year = widget.asset!.year;
      if (_year != null &&
          _year!.isNotEmpty &&
          !_years.any((item) => item.value == _year)) {
        _years.add(FormDropdownItem(value: _year!, label: _year!));
      }

      _classType = widget.asset!.classType;
      _regionId = widget.asset!.regionId;
      _quantityController.text = widget.asset!.quantity?.toString() ?? '1';
      _batchController.text = widget.asset!.batch ?? '001';

      _custodian = widget.asset!.custodian;
      if (_custodian != null &&
          _custodian!.isNotEmpty &&
          !_custodians.any((item) => item.value == _custodian)) {
        _custodians.add(
          FormDropdownItem(value: _custodian!, label: _custodian!),
        );
      }

      _location = widget.asset!.location;
      if (_location != null &&
          _location!.isNotEmpty &&
          !_locations.any((item) => item.value == _location)) {
        _locations.add(FormDropdownItem(value: _location!, label: _location!));
      }

      _status = widget.asset!.status ?? 'IN_USE';
      _remarkController.text = widget.asset!.remark ?? '';

      // 設定新增欄位的初始值
      if (widget.asset!.purchaseDate != null) {
        _purchaseDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(widget.asset!.purchaseDate!);
      }
      if (widget.asset!.warrantyDate != null) {
        _warrantyDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(widget.asset!.warrantyDate!);
      }
      if (widget.asset!.unitPrice != null) {
        _unitPriceController.text = widget.asset!.unitPrice.toString();
      }
      if (widget.asset!.color != null) {
        // F02_CR 對應的是 color
        _unitController.text = widget.asset!.color!;
      }
      if (widget.asset!.images.isNotEmpty) {
        _existingImages = List.from(widget.asset!.images);
      }
    }

    _loadToken();
    _fetchMainClasses();
    _fetchMidClasses();
    _fetchCustodians();
    _fetchLocations();
    _fetchUseTypes();
    _fetchClassTypes();
    _fetchRegions();
  }

  String get _baseUrl {
    return kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? 'http://localhost:8081'
        : 'http://10.0.2.2:8081';
  }

  String get _apiUrl {
    return '$_baseUrl/api/assets';
  }

  Future<void> _loadToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (mounted) {
      setState(() {
        _token = token;
      });
    }
  }

  Future<void> _fetchCustodians() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = (response.body.isNotEmpty)
            ? List<dynamic>.from(
                List<Map<String, dynamic>>.from(
                  (await _decodeResponse(response)) ?? [],
                ),
              )
            : []; // Workaround for simple JSON decoding.

        setState(() {
          _custodians = data
              .map<FormDropdownItem>(
                (user) => FormDropdownItem(
                  value: user['username']?.toString() ?? '',
                  label: user['fullName']?.toString() ?? '',
                ),
              )
              .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
              .toList();
          if (_custodian != null &&
              _custodian!.isNotEmpty &&
              !_custodians.any((item) => item.value == _custodian)) {
            _custodians.add(
              FormDropdownItem(value: _custodian!, label: _custodian!),
            ); // Fallback label
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching custodians: $e');
    }
  }

  Future<dynamic> _decodeResponse(http.Response res) {
    return Future.value(json.decode(res.body));
  }

  Future<void> _fetchLocations() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/code/FLOOR'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          var uniqueItems = <String, FormDropdownItem>{};
          for (var item in data) {
            final value = item['itemId']?.toString() ?? '';
            final label = item['itemName']?.toString() ?? '';
            if (value.isNotEmpty && label.isNotEmpty) {
              uniqueItems[value] = FormDropdownItem(value: value, label: label);
            }
          }
          _locations = uniqueItems.values.toList();
          if (_location != null &&
              _location!.isNotEmpty &&
              !_locations.any((item) => item.value == _location)) {
            _locations.add(
              FormDropdownItem(value: _location!, label: _location!),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }

  Future<void> _fetchUseTypes() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/code/USETYPE'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          var uniqueItems = <String, FormDropdownItem>{};
          for (var item in data) {
            final value = item['itemId']?.toString() ?? '';
            final label = item['itemName']?.toString() ?? '';
            if (value.isNotEmpty && label.isNotEmpty) {
              uniqueItems[value] = FormDropdownItem(value: value, label: label);
            }
          }
          _useTypes = uniqueItems.values.toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching USETYPE: $e');
    }
  }

  Future<void> _fetchClassTypes() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/code/CLASSTYPE'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          var uniqueItems = <String, FormDropdownItem>{};
          for (var item in data) {
            final value = item['itemId']?.toString() ?? '';
            final label = item['itemName']?.toString() ?? '';
            if (value.isNotEmpty && label.isNotEmpty) {
              uniqueItems[value] = FormDropdownItem(value: value, label: label);
            }
          }
          _classTypes = uniqueItems.values.toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching CLASSTYPE: $e');
    }
  }

  Future<void> _fetchRegions() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/code/REGION'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          var uniqueItems = <String, FormDropdownItem>{};
          for (var item in data) {
            final value = item['itemId']?.toString() ?? '';
            final label = item['itemName']?.toString() ?? '';
            if (value.isNotEmpty && label.isNotEmpty) {
              uniqueItems[value] = FormDropdownItem(value: value, label: label);
            }
          }
          _regions = uniqueItems.values.toList();
          // Initialize filtered regions based on current location if set.
          _updateFilteredRegions(_location);
        });
      }
    } catch (e) {
      debugPrint('Error fetching REGION: $e');
    }
  }

  void _updateFilteredRegions(String? locationId) {
    setState(() {
      if (locationId == null || locationId.isEmpty) {
        _filteredRegions = List.from(_regions);
      } else {
        // region's itemId format is like F004-xxx, matching floorId F004
        _filteredRegions = _regions
            .where((r) => r.value.startsWith('$locationId-'))
            .toList();
      }
      // if current _regionId is not in the filtered list, reset it.
      if (_regionId != null &&
          !_filteredRegions.any((r) => r.value == _regionId)) {
        _regionId = null;
      }
    });
  }

  Future<void> _fetchMainClasses() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/code/MAINCLASS'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          var uniqueItems = <String, FormDropdownItem>{};
          for (var item in data) {
            final value = item['itemId']?.toString() ?? '';
            final label = item['itemName']?.toString() ?? '';
            if (value.isNotEmpty && label.isNotEmpty) {
              uniqueItems[value] = FormDropdownItem(value: value, label: label);
            }
          }
          _mainClasses = uniqueItems.values.toList();
          if (_mainClass != null &&
              _mainClass!.isNotEmpty &&
              !_mainClasses.any((item) => item.value == _mainClass)) {
            _mainClasses.add(
              FormDropdownItem(value: _mainClass!, label: _mainClass!),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching main classes: $e');
    }
  }

  Future<void> _fetchMidClasses() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/code/MIDCLASS'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          var uniqueItems = <String, FormDropdownItem>{};
          for (var item in data) {
            final value = item['itemId']?.toString() ?? '';
            final label = item['itemName']?.toString() ?? '';
            if (value.isNotEmpty && label.isNotEmpty) {
              uniqueItems[value] = FormDropdownItem(value: value, label: label);
            }
          }
          _midClasses = uniqueItems.values.toList();
          if (_midClass != null &&
              _midClass!.isNotEmpty &&
              !_midClasses.any((item) => item.value == _midClass)) {
            _midClasses.add(
              FormDropdownItem(value: _midClass!, label: _midClass!),
            );
          }
          _updateFilteredMidClasses(_mainClass);
        });
      }
    } catch (e) {
      debugPrint('Error fetching mid classes: $e');
    }
  }

  void _updateFilteredMidClasses(String? mainClassId) {
    setState(() {
      if (mainClassId == null || mainClassId.isEmpty) {
        _filteredMidClasses = List.from(_midClasses);
      } else {
        // midClass format like A01, A02 matching mainClass A
        _filteredMidClasses = _midClasses
            .where((m) => m.value.startsWith(mainClassId))
            .toList();
      }
      // if current _midClass is not in the filtered list, reset it.
      if (_midClass != null &&
          !_filteredMidClasses.any((m) => m.value == _midClass)) {
        _midClass = null;
      }
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      var request = http.MultipartRequest(
        widget.asset == null ? 'POST' : 'PUT',
        Uri.parse(
          widget.asset == null ? _apiUrl : '$_apiUrl/${widget.asset!.id}',
        ),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add fields as JSON string in a part named "asset"
      // Wait, standard MultipartRequest adds fields as form-data strings.
      // But my backend expects @RequestPart("asset") AssetRequest.
      // So I need to add a file part with content-type application/json for the "asset" part.

      final assetJson =
          '''
      {
        "assetCode": "${_assetCodeController.text}",
        "name": "${_nameController.text}",
        "brand": "${_brandController.text}",
        "specification": "${_specController.text}",
        "batch": "${_batchController.text}",
        "unitPrice": ${_unitPriceController.text.isNotEmpty ? double.tryParse(_unitPriceController.text) : null},
        "color": "${_unitController.text}",
        "purchaseDate": ${_purchaseDateController.text.isNotEmpty ? '"${_purchaseDateController.text}T00:00:00Z"' : 'null'},
        "warrantyDate": ${_warrantyDateController.text.isNotEmpty ? '"${_warrantyDateController.text}T00:00:00Z"' : 'null'},
        "deletedImageIds": ${_deletedImageIds.isNotEmpty ? json.encode(_deletedImageIds) : 'null'},
        "mainClass": ${_mainClass != null ? '"$_mainClass"' : 'null'},
        "midClass": ${_midClass != null ? '"$_midClass"' : 'null'},
        "year": ${_year != null ? '"$_year"' : 'null'},
        "quantity": ${_quantityController.text},
        "custodian": ${_custodian != null ? '"$_custodian"' : 'null'},
        "location": ${_location != null ? '"$_location"' : 'null'},
        "status": ${_status != null ? '"$_status"' : '"IN_USE"'},
        "remark": "${_remarkController.text}",
        "classType": ${_classType != null ? '"$_classType"' : 'null'},
        "regionId": ${_regionId != null ? '"$_regionId"' : 'null'}
      }
      ''';

      request.files.add(
        http.MultipartFile.fromString(
          'asset',
          assetJson,
          contentType: MediaType('application', 'json'),
        ),
      );

      // Add images
      if (kIsWeb) {
        for (var image in _selectedImages) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              await image.readAsBytes(),
              filename: image.name,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      } else {
        for (var image in _selectedImages) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              image.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.asset == null ? '新增資產' : '編輯資產')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _assetCodeController,
                decoration: const InputDecoration(labelText: '資產編號 (由系統產生)'),
                readOnly: true, // 資產編號現設定為唯讀
                // 移除資產編號的必填驗證，因後端會自動產生
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名稱 (F02_NAME)'),
                validator: (v) => v!.isEmpty ? '必填' : null,
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '設備大類'),
                initialValue:
                    _mainClasses.any((item) => item.value == _mainClass)
                    ? _mainClass
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._mainClasses.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) {
                  setState(() => _mainClass = val);
                  _updateFilteredMidClasses(val);
                },
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '設備中類'),
                initialValue:
                    _filteredMidClasses.any((item) => item.value == _midClass)
                    ? _midClass
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._filteredMidClasses.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) => setState(() => _midClass = val),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '購買年度(民國)'),
                initialValue: _years.any((item) => item.value == _year)
                    ? _year
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._years.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) => setState(() => _year = val),
              ),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: '購買批次 (F02_BATCH)',
                ),
                maxLength: 3,
                validator: (v) {
                  if (v == null || v.isEmpty) return '必填';
                  if (v.length > 3) return '最多 3 碼';
                  return null;
                },
              ),
              TextFormField(
                controller: _purchaseDateController,
                decoration: InputDecoration(
                  labelText: '購買日期 (F02_DATE)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _purchaseDateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
              ),
              TextFormField(
                controller: _warrantyDateController,
                decoration: InputDecoration(
                  labelText: '保固日期 (F02_ODATE)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _warrantyDateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: '單價 (F02_SAMT)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: '單位 (F02_CR)'),
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: '廠牌'),
              ),
              TextFormField(
                controller: _specController,
                decoration: const InputDecoration(labelText: '規格'),
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: '數量'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '狀態'),
                initialValue: _useTypes.any((item) => item.value == _status)
                    ? _status
                    : 'IN_USE',
                items: [
                  const DropdownMenuItem<String>(
                    value: 'IN_USE',
                    child: Text('使用中 (預設)'),
                  ),
                  ..._useTypes.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) => setState(() => _status = val),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '保管人'),
                initialValue:
                    _custodians.any((item) => item.value == _custodian)
                    ? _custodian
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._custodians.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) => setState(() => _custodian = val),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '存放位置'),
                initialValue: _locations.any((item) => item.value == _location)
                    ? _location
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._locations.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) {
                  setState(() => _location = val);
                  _updateFilteredRegions(val);
                },
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '類別 (ClassType)'),
                initialValue:
                    _classTypes.any((item) => item.value == _classType)
                    ? _classType
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._classTypes.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) => setState(() => _classType = val),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: '區域 (RegionId)'),
                initialValue:
                    _filteredRegions.any((item) => item.value == _regionId)
                    ? _regionId
                    : null,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('無')),
                  ..._filteredRegions.map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.label)),
                  ),
                ],
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                onChanged: (val) => setState(() => _regionId = val),
              ),
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(labelText: '備註'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text('選擇圖片'),
              ),
              const SizedBox(height: 10),
              if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 1. 渲染已經存在於後端的圖片
                      ..._existingImages.map((img) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              Image.network(
                                '$_baseUrl${img.url}',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                headers: _token != null
                                    ? {'Authorization': 'Bearer $_token'}
                                    : null,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _deletedImageIds.add(img.id);
                                      _existingImages.remove(img);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // 2. 渲染新選取但未上傳的圖片
                      ..._selectedImages.asMap().entries.map((entry) {
                        int index = entry.key;
                        XFile file = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              kIsWeb
                                  ? Image.network(
                                      file.path,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(file.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAsset,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('儲存資產'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
