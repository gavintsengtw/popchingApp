import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../../models/asset_model.dart';

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
  final _quantityController = TextEditingController(text: '1');
  final _custodianController = TextEditingController();
  final _locationController = TextEditingController();
  final _statusController = TextEditingController(text: 'IN_USE');
  final _remarkController = TextEditingController();

  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _assetCodeController.text = widget.asset!.assetCode;
      _nameController.text = widget.asset!.name;
      _brandController.text = widget.asset!.brand ?? '';
      _specController.text = widget.asset!.specification ?? '';
      _quantityController.text = widget.asset!.quantity?.toString() ?? '1';
      _custodianController.text = widget.asset!.custodian ?? '';
      _locationController.text = widget.asset!.location ?? '';
      _statusController.text = widget.asset!.status ?? 'IN_USE';
      _remarkController.text = widget.asset!.remark ?? '';
    }
  }

  String get _apiUrl {
    final baseUrl = kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? 'http://localhost:8080'
        : 'http://10.0.2.2:8080';
    return '$baseUrl/api/assets';
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
        "quantity": ${_quantityController.text},
        "custodian": "${_custodianController.text}",
        "location": "${_locationController.text}",
        "status": "${_statusController.text}",
        "remark": "${_remarkController.text}"
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
      for (var image in _selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            image.path,
            contentType: MediaType('image', 'jpeg'), // Simplified for now
          ),
        );
      }

      // For web, fromPath might fail if path is blob?
      // XFile has readAsBytes. Ideally use fromBytes for platform independence.
      // But let's stick to simple mobile/desktop first. For web, need bytes.
      if (kIsWeb) {
        // Web specific handling if needed, XFile abstracts it usually but http.MultipartFile.fromPath
        // might not work with blob URL. Use fromBytes.
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
                decoration: const InputDecoration(labelText: '資產編號 (F02_NO)'),
                validator: (v) => v!.isEmpty ? '必填' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名稱 (F02_NAME)'),
                validator: (v) => v!.isEmpty ? '必填' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: '廠牌'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _specController,
                      decoration: const InputDecoration(labelText: '規格'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: '數量'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _statusController,
                      decoration: const InputDecoration(labelText: '狀態'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _custodianController,
                decoration: const InputDecoration(labelText: '保管人'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: '存放位置'),
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
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            kIsWeb
                                ? Image.network(
                                    _selectedImages[index].path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_selectedImages[index].path),
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
                    },
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
