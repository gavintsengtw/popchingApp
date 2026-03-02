package com.popching.cams.service;

import com.popching.cams.entity.Asset;
import com.popching.cams.payload.AssetRequest;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface AssetService {
    Asset createAsset(AssetRequest request, MultipartFile[] files);

    Asset updateAsset(String id, AssetRequest request, MultipartFile[] files);

    Asset getAssetById(String id);

    List<Asset> getAllAssets();

    void deleteAsset(String id);
}
