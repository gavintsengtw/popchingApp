import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide AssetImage;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          isDense: true,
        ),
        readOnly: readOnly,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<FormDropdownItem> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        initialValue: items.any((item) => item.value == value) ? value : null,
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('無')),
          ...items.map(
            (e) => DropdownMenuItem(value: e.value, child: Text(e.label)),
          ),
        ],
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.asset == null ? '✨ 新增資產' : '✏️ 編輯資產'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ResponsiveBuilder(
            builder: (context, sizingInformation) {
              final isDesktop =
                  sizingInformation.deviceScreenType ==
                      DeviceScreenType.desktop ||
                  sizingInformation.deviceScreenType == DeviceScreenType.tablet;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. 基本資訊卡片
                            _buildSectionCard(
                              title: '基本資訊 (Basic Info)',
                              icon: Icons.info_outline,
                              children: [
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _assetCodeController,
                                          label: '資產編號 (由系統產生)',
                                          readOnly: true,
                                          prefixIcon: const Icon(
                                            Icons.qr_code,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _nameController,
                                          label: '資產名稱 (F02_NAME)',
                                          validator: (v) =>
                                              v!.isEmpty ? '必填' : null,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildTextField(
                                    controller: _assetCodeController,
                                    label: '資產編號 (由系統產生)',
                                    readOnly: true,
                                    prefixIcon: const Icon(
                                      Icons.qr_code,
                                      size: 20,
                                    ),
                                  ),
                                  _buildTextField(
                                    controller: _nameController,
                                    label: '資產名稱 (F02_NAME)',
                                    validator: (v) => v!.isEmpty ? '必填' : null,
                                  ),
                                ],
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdown(
                                          label: '一般狀態',
                                          value: _status ?? 'IN_USE',
                                          items: _useTypes,
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? '必填'
                                              : null,
                                          onChanged: (val) =>
                                              setState(() => _status = val),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDropdown(
                                          label: '類別 (ClassType)',
                                          value: _classType,
                                          items: _classTypes,
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? '必填'
                                              : null,
                                          onChanged: (val) =>
                                              setState(() => _classType = val),
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildDropdown(
                                    label: '一般狀態',
                                    value: _status ?? 'IN_USE',
                                    items: _useTypes,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? '必填' : null,
                                    onChanged: (val) =>
                                        setState(() => _status = val),
                                  ),
                                  _buildDropdown(
                                    label: '類別 (ClassType)',
                                    value: _classType,
                                    items: _classTypes,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? '必填' : null,
                                    onChanged: (val) =>
                                        setState(() => _classType = val),
                                  ),
                                ],
                                _buildDropdown(
                                  label: '設備大類',
                                  value: _mainClass,
                                  items: _mainClasses,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? '必填' : null,
                                  onChanged: (val) {
                                    setState(() => _mainClass = val);
                                    _updateFilteredMidClasses(val);
                                  },
                                ),
                                _buildDropdown(
                                  label: '設備中類',
                                  value: _midClass,
                                  items: _filteredMidClasses,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? '必填' : null,
                                  onChanged: (val) =>
                                      setState(() => _midClass = val),
                                ),
                              ],
                            ),

                            // 2. 規格與採購卡片
                            _buildSectionCard(
                              title: '規格與採購 (Spec & Purchase)',
                              icon: Icons.inventory_2_outlined,
                              children: [
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _brandController,
                                          label: '廠牌',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _specController,
                                          label: '規格',
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildTextField(
                                    controller: _brandController,
                                    label: '廠牌',
                                  ),
                                  _buildTextField(
                                    controller: _specController,
                                    label: '規格',
                                  ),
                                ],
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _quantityController,
                                          label: '數量',
                                          keyboardType: TextInputType.number,
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? '必填'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _unitController,
                                          label: '單位 (F02_CR)',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _unitPriceController,
                                          label: '單價 (F02_SAMT)',
                                          keyboardType: TextInputType.number,
                                          prefixIcon: const Icon(
                                            Icons.attach_money,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildTextField(
                                    controller: _quantityController,
                                    label: '數量',
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? '必填' : null,
                                  ),
                                  _buildTextField(
                                    controller: _unitController,
                                    label: '單位 (F02_CR)',
                                  ),
                                  _buildTextField(
                                    controller: _unitPriceController,
                                    label: '單價 (F02_SAMT)',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: const Icon(
                                      Icons.attach_money,
                                      size: 20,
                                    ),
                                  ),
                                ],
                                _buildDropdown(
                                  label: '購買年度(民國)',
                                  value: _year,
                                  items: _years,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? '必填' : null,
                                  onChanged: (val) =>
                                      setState(() => _year = val),
                                ),
                                _buildTextField(
                                  controller: _batchController,
                                  label: '購買批次 (F02_BATCH)',
                                  maxLength: 3,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return '必填';
                                    if (v.length > 3) return '最多 3 碼';
                                    return null;
                                  },
                                ),
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _purchaseDateController,
                                          label: '購買日期 (F02_DATE)',
                                          readOnly: true,
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(1900),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null) {
                                                setState(() {
                                                  _purchaseDateController.text =
                                                      DateFormat(
                                                        'yyyy-MM-dd',
                                                      ).format(picked);
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _warrantyDateController,
                                          label: '保固日期 (F02_ODATE)',
                                          readOnly: true,
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(1900),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null) {
                                                setState(() {
                                                  _warrantyDateController.text =
                                                      DateFormat(
                                                        'yyyy-MM-dd',
                                                      ).format(picked);
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildTextField(
                                    controller: _purchaseDateController,
                                    label: '購買日期 (F02_DATE)',
                                    readOnly: true,
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
                                            _purchaseDateController.text =
                                                DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(picked);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  _buildTextField(
                                    controller: _warrantyDateController,
                                    label: '保固日期 (F02_ODATE)',
                                    readOnly: true,
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
                                            _warrantyDateController.text =
                                                DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(picked);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // 3. 保管與位置卡片
                            _buildSectionCard(
                              title: '保管與位置 (Custody & Location)',
                              icon: Icons.person_pin_circle_outlined,
                              children: [
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdown(
                                          label: '保管人',
                                          value: _custodian,
                                          items: _custodians,
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? '必填'
                                              : null,
                                          onChanged: (val) =>
                                              setState(() => _custodian = val),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDropdown(
                                          label: '存放位置',
                                          value: _location,
                                          items: _locations,
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? '必填'
                                              : null,
                                          onChanged: (val) {
                                            setState(() => _location = val);
                                            _updateFilteredRegions(val);
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildDropdown(
                                    label: '保管人',
                                    value: _custodian,
                                    items: _custodians,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? '必填' : null,
                                    onChanged: (val) =>
                                        setState(() => _custodian = val),
                                  ),
                                  _buildDropdown(
                                    label: '存放位置',
                                    value: _location,
                                    items: _locations,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? '必填' : null,
                                    onChanged: (val) {
                                      setState(() => _location = val);
                                      _updateFilteredRegions(val);
                                    },
                                  ),
                                ],
                                _buildDropdown(
                                  label: '區域 (RegionId)',
                                  value: _regionId,
                                  items: _filteredRegions,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? '必填' : null,
                                  onChanged: (val) =>
                                      setState(() => _regionId = val),
                                ),
                                _buildTextField(
                                  controller: _remarkController,
                                  label: '備註',
                                  maxLines: 3,
                                ),
                              ],
                            ),

                            // 4. 圖片附件卡片
                            _buildSectionCard(
                              title: '圖片附件 (Media)',
                              icon: Icons.image_outlined,
                              children: [
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Icons.add_a_photo),
                                    label: const Text('選擇/上傳圖片'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_existingImages.isNotEmpty ||
                                    _selectedImages.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      // 已經存在於後端的圖片
                                      ..._existingImages.map((img) {
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                '$_baseUrl${img.url}',
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                headers: _token != null
                                                    ? {
                                                        'Authorization':
                                                            'Bearer $_token',
                                                      }
                                                    : null,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      width: 100,
                                                      height: 100,
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            Positioned(
                                              right: -8,
                                              top: -8,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _deletedImageIds.add(
                                                      img.id,
                                                    );
                                                    _existingImages.remove(img);
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                      // 新選取但未上傳的圖片
                                      ..._selectedImages.asMap().entries.map((
                                        entry,
                                      ) {
                                        int index = entry.key;
                                        XFile file = entry.value;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: kIsWeb
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
                                            ),
                                            Positioned(
                                              right: -8,
                                              top: -8,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedImages.removeAt(
                                                      index,
                                                    );
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            // 修正捲動到底部被 BottomAppBar 遮擋的問題
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. 底部固定操作列
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            '取消 (Cancel)',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveAsset,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? '處理中...' : '儲存資產 (Save)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
