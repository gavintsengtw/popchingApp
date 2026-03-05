package com.popching.cams.repository;

import com.popching.cams.entity.ItemDictionary;
import com.popching.cams.entity.ItemDictionaryId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface ItemDictionaryRepository extends JpaRepository<ItemDictionary, ItemDictionaryId> {

    @Query("SELECT i FROM ItemDictionary i WHERE i.codeId = :codeId AND (i.deleteMark IS NULL OR i.deleteMark != 'Y')")
    List<ItemDictionary> findActiveByCodeId(@Param("codeId") String codeId);

    List<ItemDictionary> findByCodeIdAndItemIdIn(String codeId, List<String> itemIds);
}
