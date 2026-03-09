import 'package:flutter/material.dart';
import '../../models/asset_model.dart';
import '../../services/api_service.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AssetShowPage extends StatefulWidget {
  final String assetCode;

  const AssetShowPage({super.key, required this.assetCode});

  @override
  State<AssetShowPage> createState() => _AssetShowPageState();
}

class _AssetShowPageState extends State<AssetShowPage> {
  final ApiService _apiService = ApiService();
  Asset? _asset;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssetDetails();
  }

  Future<void> _fetchAssetDetails() async {
    try {
      // 呼叫免登入公開 API
      final response = await _apiService.get(
        '/assets/public/${widget.assetCode}',
      );

      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          _asset = Asset.fromJson(response);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "無法取得設備資料";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains("404")) {
        setState(() {
          _errorMessage = "查無此設備 (${widget.assetCode})";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "系統錯誤，請稍後再試。";
          _isLoading = false;
        });
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
        padding: const EdgeInsets.all(24),
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

  Widget _buildInfoRowRow(
    String label1,
    String value1,
    String label2,
    String value2, {
    bool isDesktop = false,
  }) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildInfoItem(label1, value1)),
            const SizedBox(width: 32),
            Expanded(child: _buildInfoItem(label2, value2)),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoItem(label1, value1),
          const SizedBox(height: 16),
          _buildInfoItem(label2, value2),
          const SizedBox(height: 16),
        ],
      );
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // Helper widget to display a single read-only string spanning full width
  Widget _buildFullRowInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildInfoItem(label, value),
    );
  }

  Widget _buildImagesGallery() {
    if (_asset!.images.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("目前無附加圖片", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _asset!.images.map((image) {
        String filename = image.fileName;
        String imageUrl = '${ApiService.baseUrl}/files/download/$filename';
        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: filename.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('設備明細查詢'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : ResponsiveBuilder(
                builder: (context, sizingInformation) {
                  final isDesktop =
                      sizingInformation.deviceScreenType ==
                          DeviceScreenType.desktop ||
                      sizingInformation.deviceScreenType ==
                          DeviceScreenType.tablet;

                  // Helper string conversions
                  final purchaseDateStr = _asset!.purchaseDate != null
                      ? "${_asset!.purchaseDate!.year}-${_asset!.purchaseDate!.month.toString().padLeft(2, '0')}-${_asset!.purchaseDate!.day.toString().padLeft(2, '0')}"
                      : '';
                  final warrantyDateStr = _asset!.warrantyDate != null
                      ? "${_asset!.warrantyDate!.year}-${_asset!.warrantyDate!.month.toString().padLeft(2, '0')}-${_asset!.warrantyDate!.day.toString().padLeft(2, '0')}"
                      : '';
                  final unitPriceStr = _asset!.unitPrice != null
                      ? "\$${_asset!.unitPrice}"
                      : "0";
                  final totalPriceStr = _asset!.totalPrice != null
                      ? "\$${_asset!.totalPrice}"
                      : "0";

                  return SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              _buildSectionCard(
                                title: '基本資訊 (Basic Info)',
                                icon: Icons.info_outline,
                                children: [
                                  _buildInfoRowRow(
                                    '資產編號 (Asset Code)',
                                    _asset!.assetCode,
                                    '資產名稱 (Name)',
                                    _asset!.name,
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '設備大類 (Main Class)',
                                    _asset!.mainClassName ??
                                        _asset!.mainClass ??
                                        "",
                                    '設備中類 (Mid Class)',
                                    _asset!.midClassName ??
                                        _asset!.midClass ??
                                        "",
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '購買年度 (Year)',
                                    _asset!.year ?? "",
                                    '購買批次 (Batch)',
                                    _asset!.batch ?? "",
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '狀態 (Status)',
                                    _asset!.statusName ?? _asset!.status ?? "",
                                    '單據備註 (Remark)',
                                    _asset!.remark ?? "",
                                    isDesktop: isDesktop,
                                  ),
                                ],
                              ),
                              _buildSectionCard(
                                title: '規格與採購 (Spec & Purchase)',
                                icon: Icons.shopping_bag_outlined,
                                children: [
                                  _buildInfoRowRow(
                                    '廠牌 (Brand)',
                                    _asset!.brand ?? "",
                                    '型號與規格 (Specification)',
                                    _asset!.specification ?? "",
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '材料單位 (Material Unit)',
                                    _asset!.color ?? "",
                                    '數量 (Quantity)',
                                    _asset!.quantity?.toString() ?? "",
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '採購日期 (Purchase Date)',
                                    purchaseDateStr,
                                    '保固期限 (Warranty Date)',
                                    warrantyDateStr,
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '耐用年限 (Useful Life, Years)',
                                    _asset!.usefulLife?.toString() ?? "",
                                    '單價 (Unit Price)',
                                    unitPriceStr,
                                    isDesktop: isDesktop,
                                  ),
                                  _buildFullRowInfoItem(
                                    '總價 (Total Price)',
                                    totalPriceStr,
                                  ),
                                ],
                              ),
                              _buildSectionCard(
                                title: '保管與位置 (Custody & Location)',
                                icon: Icons.location_on_outlined,
                                children: [
                                  _buildInfoRowRow(
                                    '使用部門 (Dept)',
                                    _asset!.departmentName ??
                                        _asset!.userDept ??
                                        "",
                                    '保管人 (Custodian)',
                                    _asset!.custodianName ??
                                        _asset!.custodian ??
                                        "",
                                    isDesktop: isDesktop,
                                  ),
                                  _buildInfoRowRow(
                                    '存放地點 (Location)',
                                    _asset!.locationName ??
                                        _asset!.location ??
                                        "",
                                    '盤點狀態 (Class Type)',
                                    _asset!.classTypeName ??
                                        _asset!.classType ??
                                        "",
                                    isDesktop: isDesktop,
                                  ),
                                  _buildFullRowInfoItem(
                                    '所屬區域 (Region)',
                                    _asset!.regionName ??
                                        _asset!.regionId ??
                                        "",
                                  ),
                                ],
                              ),
                              _buildSectionCard(
                                title: '圖片預覽 (Images Preview)',
                                icon: Icons.image_outlined,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildImagesGallery(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
