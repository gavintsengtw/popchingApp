package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "fixUploadFile")
public class FixUploadFile {

    @Id
    @Column(name = "UID", length = 50)
    private String id;

    @Column(name = "F02_NO", length = 50)
    private String assetCode;

    @Column(name = "filename")
    private String fileName;

    @Column(name = "ITEMS")
    private String items; // Type or sequence?

    // Add other fields if known, or just these for now from user request.
    // User request: F02_NO, ITEMS, filename, UID
}
