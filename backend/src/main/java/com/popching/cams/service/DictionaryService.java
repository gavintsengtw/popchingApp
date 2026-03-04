package com.popching.cams.service;

import com.popching.cams.entity.ItemDictionary;
import com.popching.cams.entity.ItemDictionaryId;
import com.popching.cams.repository.ItemDictionaryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class DictionaryService {

    @Autowired
    private ItemDictionaryRepository dictionaryRepository;

    public List<ItemDictionary> getItemsByCode(String codeId) {
        return dictionaryRepository.findActiveByCodeId(codeId);
    }

    public List<ItemDictionary> getAllItems() {
        return dictionaryRepository.findAll();
    }

    public Optional<ItemDictionary> getItemById(String codeId, String itemId) {
        return dictionaryRepository.findById(new ItemDictionaryId(codeId, itemId));
    }

    public ItemDictionary createItem(ItemDictionary item) {
        return dictionaryRepository.save(item);
    }

    public ItemDictionary updateItem(String codeId, String itemId, ItemDictionary itemDetails) {
        ItemDictionaryId id = new ItemDictionaryId(codeId, itemId);
        ItemDictionary item = dictionaryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Item not found with id: " + id));
        item.setItemName(itemDetails.getItemName());
        return dictionaryRepository.save(item);
    }

    public void deleteItem(String codeId, String itemId) {
        ItemDictionaryId id = new ItemDictionaryId(codeId, itemId);
        ItemDictionary item = dictionaryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Item not found with id: " + id));
        item.setDeleteMark("Y");
        dictionaryRepository.save(item);
    }
}
