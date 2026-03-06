package com.popching.cams.service;

import com.popching.cams.entity.Asset;
import com.popching.cams.payload.AssetRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface AssetService {
    Asset createAsset(AssetRequest request, MultipartFile[] files);

    Asset updateAsset(String id, AssetRequest request, MultipartFile[] files);

    Asset getAssetById(String id);

    List<Asset> getAllAssets();

    Page<Asset> searchAssets(String mainClass, String midClass, String year, String custodian, String location,
            String keyword, Pageable pageable);

    void voidAsset(String id);

    void batchUpdateCustodian(List<String> assetIds, String newCustodian);

    void batchUpdateLocation(List<String> assetIds, String newLocation);
}
