package com.popching.cams.controller;

import com.popching.cams.entity.ItemDictionary;
import com.popching.cams.service.DictionaryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/dictionary")
public class DictionaryController {

    @Autowired
    private DictionaryService dictionaryService;

    @GetMapping
    public List<ItemDictionary> getAllItems() {
        return dictionaryService.getAllItems();
    }

    @GetMapping("/code/{codeId}")
    public List<ItemDictionary> getItemsByCode(@PathVariable String codeId) {
        // e.g. codeId = 'ASSET_CLASS_MAIN' (大類), 'ASSET_CLASS_SUB' (小類), 'LOCATION'
        // (倉儲)
        return dictionaryService.getItemsByCode(codeId);
    }

    @GetMapping("/{codeId}/{itemId}")
    public ResponseEntity<ItemDictionary> getItemById(
            @PathVariable(value = "codeId") String codeId,
            @PathVariable(value = "itemId") String itemId) {
        ItemDictionary item = dictionaryService.getItemById(codeId, itemId)
                .orElseThrow(() -> new RuntimeException("Item not found"));
        return ResponseEntity.ok().body(item);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_ADD')")
    public ItemDictionary createItem(@RequestBody ItemDictionary item) {
        return dictionaryService.createItem(item);
    }

    @PutMapping("/{codeId}/{itemId}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<ItemDictionary> updateItem(
            @PathVariable(value = "codeId") String codeId,
            @PathVariable(value = "itemId") String itemId,
            @RequestBody ItemDictionary itemDetails) {
        ItemDictionary updatedItem = dictionaryService.updateItem(codeId, itemId, itemDetails);
        return ResponseEntity.ok(updatedItem);
    }

    @DeleteMapping("/{codeId}/{itemId}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_DELETE')")
    public ResponseEntity<?> deleteItem(
            @PathVariable(value = "codeId") String codeId,
            @PathVariable(value = "itemId") String itemId) {
        dictionaryService.deleteItem(codeId, itemId);
        return ResponseEntity.ok().build();
    }
}
