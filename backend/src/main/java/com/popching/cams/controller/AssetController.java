package com.popching.cams.controller;

import com.popching.cams.entity.Asset;
import com.popching.cams.payload.AssetRequest;
import com.popching.cams.service.AssetService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/assets")
public class AssetController {

    @Autowired
    private AssetService assetService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public Page<Asset> searchAssets(
            @RequestParam(required = false) String mainClass,
            @RequestParam(required = false) String midClass,
            @RequestParam(required = false) String year,
            @RequestParam(required = false) String custodian,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase(Sort.Direction.ASC.name()) ? Sort.by(sortBy).ascending()
                : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);

        return assetService.searchAssets(mainClass, midClass, year, custodian, location, keyword, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Asset> getAssetById(@PathVariable(value = "id") String assetId) {
        Asset asset = assetService.getAssetById(assetId); // Delegated to service
        return ResponseEntity.ok().body(asset);
    }

    @PostMapping(consumes = { "multipart/form-data" }) // Added consumes
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_ADD')")
    public ResponseEntity<Asset> createAsset(
            @RequestPart("asset") AssetRequest assetRequest, // Changed to @RequestPart
            @RequestPart(value = "files", required = false) MultipartFile[] files) { // Added files

        Asset savedAsset = assetService.createAsset(assetRequest, files); // Delegated to service
        return new ResponseEntity<>(savedAsset, HttpStatus.CREATED);
    }

    @PutMapping(value = "/{id}", consumes = { "multipart/form-data" }) // Added consumes
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<Asset> updateAsset(
            @PathVariable(value = "id") String assetId,
            @RequestPart("asset") AssetRequest assetRequest, // Changed to @RequestPart
            @RequestPart(value = "files", required = false) MultipartFile[] files) { // Added files

        Asset updatedAsset = assetService.updateAsset(assetId, assetRequest, files); // Delegated to service
        return ResponseEntity.ok(updatedAsset);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_DELETE')")
    public ResponseEntity<?> voidAsset(@PathVariable(value = "id") String assetId) {
        assetService.voidAsset(assetId); // Voiding rather than deleting
        return ResponseEntity.ok().build();
    }

    @PutMapping("/batch/custodian")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<?> batchUpdateCustodian(
            @RequestBody com.popching.cams.payload.AssetBatchUpdateRequest request) {
        assetService.batchUpdateCustodian(request.getAssetIds(), request.getNewValue());
        return ResponseEntity.ok().build();
    }

    @PutMapping("/batch/location")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<?> batchUpdateLocation(
            @RequestBody com.popching.cams.payload.AssetBatchUpdateRequest request) {
        assetService.batchUpdateLocation(request.getAssetIds(), request.getNewValue());
        return ResponseEntity.ok().build();
    }
}
