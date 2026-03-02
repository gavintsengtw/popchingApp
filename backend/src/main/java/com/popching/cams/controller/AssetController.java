package com.popching.cams.controller;

import com.popching.cams.entity.Asset;
import com.popching.cams.payload.AssetRequest;
import com.popching.cams.service.AssetService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/assets")
public class AssetController {

    @Autowired
    private AssetService assetService; // Changed from AssetRepository

    @GetMapping
    public List<Asset> getAllAssets() {
        return assetService.getAllAssets(); // Delegated to service
    }

    @GetMapping("/{id}")
    public ResponseEntity<Asset> getAssetById(@PathVariable(value = "id") String assetId) {
        Asset asset = assetService.getAssetById(assetId); // Delegated to service
        return ResponseEntity.ok().body(asset);
    }

    @PostMapping(consumes = { "multipart/form-data" }) // Added consumes
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Asset> createAsset(
            @RequestPart("asset") AssetRequest assetRequest, // Changed to @RequestPart
            @RequestPart(value = "files", required = false) MultipartFile[] files) { // Added files

        Asset savedAsset = assetService.createAsset(assetRequest, files); // Delegated to service
        return new ResponseEntity<>(savedAsset, HttpStatus.CREATED);
    }

    @PutMapping(value = "/{id}", consumes = { "multipart/form-data" }) // Added consumes
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Asset> updateAsset(
            @PathVariable(value = "id") String assetId,
            @RequestPart("asset") AssetRequest assetRequest, // Changed to @RequestPart
            @RequestPart(value = "files", required = false) MultipartFile[] files) { // Added files

        Asset updatedAsset = assetService.updateAsset(assetId, assetRequest, files); // Delegated to service
        return ResponseEntity.ok(updatedAsset);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteAsset(@PathVariable(value = "id") String assetId) {
        assetService.deleteAsset(assetId); // Delegated to service
        return ResponseEntity.ok().build();
    }
}
