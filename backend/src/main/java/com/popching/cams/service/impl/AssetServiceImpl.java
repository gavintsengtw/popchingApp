package com.popching.cams.service.impl;

import com.popching.cams.entity.Asset;
import com.popching.cams.entity.FixUploadFile;
import com.popching.cams.exception.ResourceNotFoundException;
import com.popching.cams.payload.AssetRequest;
import com.popching.cams.repository.AssetRepository;
import com.popching.cams.repository.FixbaseHisRepository;
import com.popching.cams.repository.UserRepository;
import com.popching.cams.repository.ItemDictionaryRepository;
import com.popching.cams.entity.FixbaseHis;
import com.popching.cams.entity.User;
import com.popching.cams.entity.ItemDictionary;
import com.popching.cams.service.AssetService;
import com.popching.cams.service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.Authentication;
import jakarta.persistence.criteria.Predicate;

import java.time.LocalDateTime;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.Collections;
import java.util.Objects;

@Service
public class AssetServiceImpl implements AssetService {

    @Autowired
    private AssetRepository assetRepository;

    @Autowired
    private FixbaseHisRepository fixbaseHisRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ItemDictionaryRepository itemDictionaryRepository;

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
            String year = asset.getYear();
            String midClass = asset.getMidClass();
            String batch = asset.getBatch();

            if (year != null && !year.isEmpty() && midClass != null && !midClass.isEmpty() && batch != null
                    && !batch.isEmpty()) {
                List<Asset> sameYearAndBatchAssets = assetRepository.findByYearAndBatch(year, batch);
                int maxSeq = 0;
                for (Asset a : sameYearAndBatchAssets) {
                    String code = a.getAssetCode();
                    if (code != null && code.startsWith("PC-")) {
                        String[] parts = code.split("-");
                        if (parts.length >= 5) {
                            try {
                                int seq = Integer.parseInt(parts[parts.length - 1]);
                                if (seq > maxSeq) {
                                    maxSeq = seq;
                                }
                            } catch (NumberFormatException e) {
                                // Ignore non-numeric sequences
                            }
                        }
                    }
                }
                maxSeq++;
                String newSequence = String.format("%03d", maxSeq);
                String generatedCode = "PC-" + year + "-" + midClass + "-" + batch + "-" + newSequence;
                asset.setAssetCode(generatedCode);
            } else {
                throw new IllegalArgumentException("購買年度、設備中類、購買批次為產生資產編號必填欄位。");
            }
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

        asset = assetRepository.save(asset);
        populateTransientFields(Collections.singletonList(asset));
        return asset;
    }

    @Override
    @Transactional
    public Asset updateAsset(String id, AssetRequest request, MultipartFile[] files) {
        Asset asset = assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));

        // Backup to FixbaseHis before update
        FixbaseHis history = new FixbaseHis();
        history.setId(UUID.randomUUID().toString());
        history.setMainClass(asset.getMainClass());
        history.setMidClass(asset.getMidClass());
        history.setYear(asset.getYear());
        history.setBatch(asset.getBatch());
        history.setAssetCode(asset.getAssetCode());
        history.setBrand(asset.getBrand());
        history.setSpecification(asset.getSpecification());
        history.setName(asset.getName());
        history.setColor(asset.getColor());
        history.setQuantity(asset.getQuantity());
        history.setUnitPrice(asset.getUnitPrice());
        history.setTotalPrice(asset.getTotalPrice());
        history.setUserDept(asset.getUserDept());
        history.setCustodian(asset.getCustodian());
        history.setLocation(asset.getLocation());
        history.setPurchaseDate(asset.getPurchaseDate());
        history.setUsefulLife(asset.getUsefulLife());
        history.setWarrantyDate(asset.getWarrantyDate());
        history.setPcName(asset.getPcName());
        history.setFileDescription(asset.getFileDescription());
        history.setRemark(asset.getRemark());
        history.setPhotoName(asset.getPhotoName());
        history.setStatus(asset.getStatus());
        history.setLeaseDept(asset.getLeaseDept());
        history.setSize(asset.getSize());
        history.setCreatedBy(asset.getCreatedBy());
        history.setLastModifiedBy(asset.getLastModifiedBy());
        history.setImgIdList(asset.getImgIdList());
        history.setClassType(asset.getClassType());
        history.setRegionId(asset.getRegionId());
        history.setRagicSh(asset.getRagicSh());
        history.setRagicId(asset.getRagicId());

        // Tracking fields
        history.setChangeType("資料變更");
        history.setChangeDte(LocalDateTime.now());
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()) {
            history.setChangeUser(auth.getName());
        }

        fixbaseHisRepository.save(history);

        mapRequestToAsset(request, asset);

        // 處理刪除的舊圖片
        List<String> deletedIds = request.getDeletedImageIds();
        if (deletedIds != null && !deletedIds.isEmpty() && asset.getImages() != null) {
            java.util.Iterator<FixUploadFile> iterator = asset.getImages().iterator();
            while (iterator.hasNext()) {
                FixUploadFile img = iterator.next();
                if (deletedIds.contains(img.getId())) {
                    // 實體刪除檔案
                    fileStorageService.deleteFile(img.getFileName());
                    // 從關聯中移除，由 JPA OrphanRemoval 負責清除 DB 紀錄
                    iterator.remove();
                }
            }
        }

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

        asset = assetRepository.save(asset);
        populateTransientFields(Collections.singletonList(asset));
        return asset;
    }

    @Override
    public Asset getAssetById(String id) {
        Asset asset = assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));
        populateTransientFields(Collections.singletonList(asset));
        return asset;
    }

    @Override
    public Asset getAssetByCode(String code) {
        List<Asset> assets = assetRepository.findByAssetCode(code);
        if (assets == null || assets.isEmpty()) {
            throw new ResourceNotFoundException("Asset", "assetCode", code);
        }
        Asset asset = assets.get(0);
        populateTransientFields(Collections.singletonList(asset));
        return asset;
    }

    @Override
    public List<Asset> getAllAssets() {
        List<Asset> assets = assetRepository.findAll();
        populateTransientFields(assets);
        return assets;
    }

    @Override
    public Page<Asset> searchAssets(String mainClass, String midClass, String year, String custodian, String location,
            String keyword, Pageable pageable) {
        Page<Asset> page = assetRepository.findAll((Specification<Asset>) (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (mainClass != null && !mainClass.isEmpty()) {
                predicates.add(cb.equal(root.get("mainClass"), mainClass));
            }
            if (midClass != null && !midClass.isEmpty()) {
                predicates.add(cb.equal(root.get("midClass"), midClass));
            }
            if (year != null && !year.isEmpty()) {
                predicates.add(cb.equal(root.get("year"), year));
            }
            if (custodian != null && !custodian.isEmpty()) {
                predicates.add(cb.like(cb.lower(root.get("custodian")), "%" + custodian.toLowerCase() + "%"));
            }
            if (location != null && !location.isEmpty()) {
                predicates.add(cb.equal(root.get("location"), location));
            }
            if (keyword != null && !keyword.isEmpty()) {
                String likeKeyword = "%" + keyword.toLowerCase() + "%";
                Predicate nameMatch = cb.like(cb.lower(root.get("name")), likeKeyword);
                Predicate codeMatch = cb.like(cb.lower(root.get("assetCode")), likeKeyword);
                Predicate brandMatch = cb.like(cb.lower(root.get("brand")), likeKeyword);
                Predicate specMatch = cb.like(cb.lower(root.get("specification")), likeKeyword);
                predicates.add(cb.or(nameMatch, codeMatch, brandMatch, specMatch));
            }

            // Always filter out voided assets ("V" for Voided or whatever specific code
            // used)
            // Currently assuming "V" means Voided. Modify as needed.
            // predicates.add(cb.notEqual(root.get("status"), "V"));

            return cb.and(predicates.toArray(new Predicate[0]));
        }, pageable);

        populateTransientFields(page.getContent());
        return page;
    }

    @Override
    @Transactional
    public void voidAsset(String id) {
        Asset asset = assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));
        asset.setStatus("V"); // "V" denotes Void in F02_USETYPE
        assetRepository.save(asset);

        // Record history for void
        FixbaseHis history = new FixbaseHis();
        history.setId(UUID.randomUUID().toString());
        history.setMainClass(asset.getMainClass());
        history.setMidClass(asset.getMidClass());
        history.setYear(asset.getYear());
        history.setBatch(asset.getBatch());
        history.setAssetCode(asset.getAssetCode());
        history.setBrand(asset.getBrand());
        history.setSpecification(asset.getSpecification());
        history.setName(asset.getName());
        history.setColor(asset.getColor());
        history.setQuantity(asset.getQuantity());
        history.setUnitPrice(asset.getUnitPrice());
        history.setTotalPrice(asset.getTotalPrice());
        history.setUserDept(asset.getUserDept());
        history.setCustodian(asset.getCustodian());
        history.setLocation(asset.getLocation());
        history.setPurchaseDate(asset.getPurchaseDate());
        history.setUsefulLife(asset.getUsefulLife());
        history.setWarrantyDate(asset.getWarrantyDate());
        history.setPcName(asset.getPcName());
        history.setFileDescription(asset.getFileDescription());
        history.setRemark(asset.getRemark());
        history.setPhotoName(asset.getPhotoName());
        history.setStatus(asset.getStatus()); // Will be "V"
        history.setLeaseDept(asset.getLeaseDept());
        history.setSize(asset.getSize());
        history.setCreatedBy(asset.getCreatedBy());
        history.setLastModifiedBy(asset.getLastModifiedBy());
        history.setImgIdList(asset.getImgIdList());
        history.setClassType(asset.getClassType());
        history.setRegionId(asset.getRegionId());
        history.setRagicSh(asset.getRagicSh());
        history.setRagicId(asset.getRagicId());

        // Tracking fields
        history.setChangeType("資料作廢");
        history.setChangeDte(LocalDateTime.now());
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()) {
            history.setChangeUser(auth.getName());
        }

        fixbaseHisRepository.save(history);
    }

    @Override
    @Transactional
    public void batchUpdateCustodian(List<String> assetIds, String newCustodian) {
        User user = null;
        if (newCustodian != null && !newCustodian.isEmpty()) {
            user = userRepository.findByUsername(newCustodian).orElse(null);
        }

        for (String id : assetIds) {
            Asset asset = assetRepository.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));

            asset.setCustodian(newCustodian);
            if (user != null) {
                if (user.getDepartments() != null && !user.getDepartments().isEmpty()) {
                    asset.setUserDept(user.getDepartments().iterator().next().getId());
                } else if (user.getUserDept() != null) {
                    asset.setUserDept(user.getUserDept());
                }
            }

            assetRepository.save(asset);

            String changeType = "變更保管人";
            createHistoryRecord(asset, changeType);
        }
    }

    @Override
    @Transactional
    public void batchUpdateLocation(List<String> assetIds, String newLocation) {
        for (String id : assetIds) {
            Asset asset = assetRepository.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Asset", "id", id));

            asset.setLocation(newLocation);
            assetRepository.save(asset);

            String changeType = "變更存放位置";
            createHistoryRecord(asset, changeType);
        }
    }

    private void createHistoryRecord(Asset asset, String changeType) {
        FixbaseHis history = new FixbaseHis();
        history.setId(UUID.randomUUID().toString());
        history.setMainClass(asset.getMainClass());
        history.setMidClass(asset.getMidClass());
        history.setYear(asset.getYear());
        history.setBatch(asset.getBatch());
        history.setAssetCode(asset.getAssetCode());
        history.setBrand(asset.getBrand());
        history.setSpecification(asset.getSpecification());
        history.setName(asset.getName());
        history.setColor(asset.getColor());
        history.setQuantity(asset.getQuantity());
        history.setUnitPrice(asset.getUnitPrice());
        history.setTotalPrice(asset.getTotalPrice());
        history.setUserDept(asset.getUserDept());
        history.setCustodian(asset.getCustodian());
        history.setLocation(asset.getLocation());
        history.setPurchaseDate(asset.getPurchaseDate());
        history.setUsefulLife(asset.getUsefulLife());
        history.setWarrantyDate(asset.getWarrantyDate());
        history.setPcName(asset.getPcName());
        history.setFileDescription(asset.getFileDescription());
        history.setRemark(asset.getRemark());
        history.setPhotoName(asset.getPhotoName());
        history.setStatus(asset.getStatus());
        history.setLeaseDept(asset.getLeaseDept());
        history.setSize(asset.getSize());
        history.setCreatedBy(asset.getCreatedBy());
        history.setLastModifiedBy(asset.getLastModifiedBy());
        history.setImgIdList(asset.getImgIdList());
        history.setClassType(asset.getClassType());
        history.setRegionId(asset.getRegionId());
        history.setRagicSh(asset.getRagicSh());
        history.setRagicId(asset.getRagicId());

        history.setChangeType(changeType);
        history.setChangeDte(LocalDateTime.now());
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()) {
            history.setChangeUser(auth.getName());
        }

        fixbaseHisRepository.save(history);
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
        asset.setColor(request.getColor());
        asset.setFileDescription(request.getFileDescription());
        asset.setClassType(request.getClassType());
        asset.setRegionId(request.getRegionId());
    }

    private void populateTransientFields(List<Asset> assets) {
        if (assets == null || assets.isEmpty())
            return;

        Set<String> custodianIds = assets.stream()
                .map(Asset::getCustodian)
                .filter(c -> c != null && !c.isEmpty())
                .collect(Collectors.toSet());

        Set<String> locationIds = assets.stream()
                .map(Asset::getLocation)
                .filter(l -> l != null && !l.isEmpty())
                .collect(Collectors.toSet());

        Map<String, User> userMap = custodianIds.isEmpty() ? Collections.emptyMap()
                : userRepository.findByUsernameIn(custodianIds).stream()
                        .collect(Collectors.toMap(User::getUsername, u -> u)); // Assuming F02_MNO stores
                                                                               // account/username logic. Might be
                                                                               // username and not badgenumber(id)!

        Map<String, String> locationMap = locationIds.isEmpty() ? Collections.emptyMap()
                : itemDictionaryRepository.findByCodeIdAndItemIdIn("FLOOR", new ArrayList<>(locationIds)).stream()
                        .collect(Collectors.toMap(ItemDictionary::getItemId, ItemDictionary::getItemName));

        Set<String> mainClassIds = assets.stream().map(Asset::getMainClass).filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Set<String> midClassIds = assets.stream().map(Asset::getMidClass).filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Set<String> statusIds = assets.stream().map(Asset::getStatus).filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Set<String> regionIds = assets.stream().map(Asset::getRegionId).filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Set<String> classTypeIds = assets.stream().map(Asset::getClassType).filter(Objects::nonNull)
                .collect(Collectors.toSet());

        Map<String, String> mainClassMap = mainClassIds.isEmpty() ? Collections.emptyMap()
                : itemDictionaryRepository.findByCodeIdAndItemIdIn("MAINCLASS", new ArrayList<>(mainClassIds)).stream()
                        .collect(Collectors.toMap(ItemDictionary::getItemId, ItemDictionary::getItemName));
        Map<String, String> midClassMap = midClassIds.isEmpty() ? Collections.emptyMap()
                : itemDictionaryRepository.findByCodeIdAndItemIdIn("MIDCLASS", new ArrayList<>(midClassIds)).stream()
                        .collect(Collectors.toMap(ItemDictionary::getItemId, ItemDictionary::getItemName));
        Map<String, String> statusMap = statusIds.isEmpty() ? Collections.emptyMap()
                : itemDictionaryRepository.findByCodeIdAndItemIdIn("USETYPE", new ArrayList<>(statusIds)).stream()
                        .collect(Collectors.toMap(ItemDictionary::getItemId, ItemDictionary::getItemName));
        Map<String, String> regionMap = regionIds.isEmpty() ? Collections.emptyMap()
                : itemDictionaryRepository.findByCodeIdAndItemIdIn("REGION", new ArrayList<>(regionIds)).stream()
                        .collect(Collectors.toMap(ItemDictionary::getItemId, ItemDictionary::getItemName));
        Map<String, String> classTypeMap = classTypeIds.isEmpty() ? Collections.emptyMap()
                : itemDictionaryRepository.findByCodeIdAndItemIdIn("CLASSTYPE", new ArrayList<>(classTypeIds)).stream()
                        .collect(Collectors.toMap(ItemDictionary::getItemId, ItemDictionary::getItemName));

        for (Asset asset : assets) {
            if (asset.getCustodian() != null) {
                User user = userMap.get(asset.getCustodian());
                if (user != null) {
                    asset.setCustodianName(user.getFullName());
                    if (user.getDepartments() != null && !user.getDepartments().isEmpty()) {
                        asset.setDepartmentName(user.getDepartments().iterator().next().getName());
                    }
                }
            }
            if (asset.getLocation() != null) {
                asset.setLocationName(locationMap.get(asset.getLocation()));
            }
            if (asset.getMainClass() != null)
                asset.setMainClassName(mainClassMap.get(asset.getMainClass()));
            if (asset.getMidClass() != null)
                asset.setMidClassName(midClassMap.get(asset.getMidClass()));
            if (asset.getStatus() != null)
                asset.setStatusName(statusMap.get(asset.getStatus()));
            if (asset.getRegionId() != null)
                asset.setRegionName(regionMap.get(asset.getRegionId()));
            if (asset.getClassType() != null)
                asset.setClassTypeName(classTypeMap.get(asset.getClassType()));
        }
    }
}
