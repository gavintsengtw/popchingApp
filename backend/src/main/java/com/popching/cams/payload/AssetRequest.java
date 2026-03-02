package com.popching.cams.payload;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class AssetRequest {
    // ID is usually auto-generated or passed in path, but for legacy compatibility
    // we might need to handle it.
    // Let's assume ID (SYSNUM) is generated or provided.

    private String assetCode; // F02_NO
    private String name; // F02_NAME
    private String brand; // F02_BRAND
    private String specification; // F02_SPEC
    private String model; // Mapping to F02_SPEC or separate? Legacy schema didn't have specific match,
                          // maybe part of SPEC.
    private String mainClass;
    private String midClass;
    private String year;
    private String batch;

    private BigDecimal quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;

    private String userDept;
    private String custodian;
    private String location;

    private LocalDate purchaseDate;
    private LocalDate warrantyDate;
    private String usefulLife;

    private String status; // F02_USETYPE
    private String remark;
    private String fileDescription;

    // For relations, we now pass Strings directly as per legacy schema
}
