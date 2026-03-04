package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "FIXITEMS")
@IdClass(ItemDictionaryId.class)
public class ItemDictionary {

    @Id
    @Column(name = "CODEID", length = 50, nullable = false)
    private String codeId;

    @Id
    @Column(name = "ITEMID", length = 50, nullable = false)
    private String itemId;

    @Column(name = "ITEMNAME", length = 100, nullable = false)
    private String itemName;

    @Column(name = "deleteMark", length = 1)
    private String deleteMark;
}
