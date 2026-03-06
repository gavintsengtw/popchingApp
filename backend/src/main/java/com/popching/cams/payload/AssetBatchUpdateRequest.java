package com.popching.cams.payload;

import java.util.List;

public class AssetBatchUpdateRequest {
    private List<String> assetIds;
    private String newValue;

    public List<String> getAssetIds() {
        return assetIds;
    }

    public void setAssetIds(List<String> assetIds) {
        this.assetIds = assetIds;
    }

    public String getNewValue() {
        return newValue;
    }

    public void setNewValue(String newValue) {
        this.newValue = newValue;
    }
}
