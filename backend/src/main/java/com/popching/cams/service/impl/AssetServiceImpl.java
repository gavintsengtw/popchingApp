package com.popching.cams.service.impl;

import com.popching.cams.entity.Asset;
import com.popching.cams.entity.FixUploadFile;
import com.popching.cams.exception.ResourceNotFoundException;
import com.popching.cams.payload.AssetRequest;
import com.popching.cams.repository.AssetRepository;
import com.popching.cams.service.AssetService;
import com.popching.cams.service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class AssetServiceImpl implements AssetService {

    @Autowired
    private AssetRepository assetRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Override
    @Transactional
    public Asset createAsset(AssetRequest request, MultipartFile[] files) {
        Asset asset = new Asset();
        if (asset.getId() == null) {
            asset.setId(UUID.randomUUID().toString());
        }
        mapRequestToAsset(request, asset);

        // Ensure assetCode is present as it relates to files
        if (asset.getAssetCode() == null || asset.getAssetCode().isEmpty()) {
            // If not provided, maybe generate or throw?
            // Assuming provided in request for legacy compatibility
        }

        if (files != null && files.length > 0) {
            List<FixUploadFile> images = new ArrayList<>();
            for (MultipartFile file : files) {
                if (file.isEmpty())
                    continue;
                String fileName = fileStorageService.storeFile(file);

                FixUploadFile uploadFile = new FixUploadFile();
                uploadFile.setId(UUID.randomUUID().toString());
                uploadFile.setAssetCode(asset.getAssetCode());
                uploadFile.setFileName(fileName);
                uploadFile.setItems("1"); // Default value or sequence needs logic

                images.add(uploadFile);
            }
            asset.setImages(images);
        }

        return assetRepository.save(asset);
    }

    @Override
    @Transactional
    public Asset updateAsset(String id, AssetRequest request, MultipartFile[] files) {
        Asset asset = assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));

        mapRequestToAsset(request, asset);

        if (files != null && files.length > 0) {
            List<FixUploadFile> currentImages = asset.getImages();
            if (currentImages == null) {
                currentImages = new ArrayList<>();
            }

            for (MultipartFile file : files) {
                if (file.isEmpty())
                    continue;
                String fileName = fileStorageService.storeFile(file);

                FixUploadFile uploadFile = new FixUploadFile();
                uploadFile.setId(UUID.randomUUID().toString());
                uploadFile.setAssetCode(asset.getAssetCode());
                uploadFile.setFileName(fileName);
                uploadFile.setItems("1");

                currentImages.add(uploadFile);
            }
            asset.setImages(currentImages);
        }

        return assetRepository.save(asset);
    }

    @Override
    public Asset getAssetById(String id) {
        return assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));
    }

    @Override
    public List<Asset> getAllAssets() {
        return assetRepository.findAll();
    }

    @Override
    public void deleteAsset(String id) {
        Asset asset = assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));
        assetRepository.delete(asset);
    }

    private void mapRequestToAsset(AssetRequest request, Asset asset) {
        asset.setAssetCode(request.getAssetCode());
        asset.setName(request.getName());
        asset.setBrand(request.getBrand());
        asset.setSpecification(request.getSpecification());

        asset.setMainClass(request.getMainClass());
        asset.setMidClass(request.getMidClass());
        asset.setYear(request.getYear());
        asset.setBatch(request.getBatch());

        asset.setQuantity(request.getQuantity());
        asset.setUnitPrice(request.getUnitPrice());
        asset.setTotalPrice(request.getTotalPrice());

        asset.setUserDept(request.getUserDept());
        asset.setCustodian(request.getCustodian());
        asset.setLocation(request.getLocation());

        asset.setPurchaseDate(request.getPurchaseDate());
        asset.setWarrantyDate(request.getWarrantyDate());
        asset.setUsefulLife(request.getUsefulLife());

        asset.setStatus(request.getStatus());
        asset.setRemark(request.getRemark());
        asset.setFileDescription(request.getFileDescription());
    }
}
