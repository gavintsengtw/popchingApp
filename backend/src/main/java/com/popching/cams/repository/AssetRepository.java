package com.popching.cams.repository;

import com.popching.cams.entity.Asset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AssetRepository extends JpaRepository<Asset, String>, JpaSpecificationExecutor<Asset> {
    List<Asset> findByAssetCode(String assetCode);

    List<Asset> findByYearAndBatch(String year, String batch);
}
