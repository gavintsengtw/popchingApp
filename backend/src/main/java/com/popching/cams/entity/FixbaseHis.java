package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "FIXBASE_HIS")
@AttributeOverrides({
        @AttributeOverride(name = "createdAt", column = @Column(name = "CRDTE")),
        @AttributeOverride(name = "updatedAt", column = @Column(name = "MODDTE"))
})
public class FixbaseHis extends BaseEntity {

    @Id
    @Column(name = "SYSNUM", length = 50)
    private String id; // Use a new UUID for the history record SYSNUM

    @Column(name = "F02_MAINCLASS")
    private String mainClass;

    @Column(name = "F02_MIDCLASS")
    private String midClass;

    @Column(name = "F02_YEAR")
    private String year;

    @Column(name = "F02_BATCH")
    private String batch;

    @Column(name = "F02_NO")
    private String assetCode; // Original Asset ID

    @Column(name = "F02_BRAND")
    private String brand;

    @Column(name = "F02_SPEC")
    private String specification;

    @Column(name = "F02_NAME")
    private String name;

    @Column(name = "F02_CR")
    private String color;

    @Column(name = "F02_NUM")
    private BigDecimal quantity;

    @Column(name = "F02_SAMT")
    private BigDecimal unitPrice;

    @Column(name = "F02_AMT")
    private BigDecimal totalPrice;

    @Column(name = "F02_UDEPT")
    private String userDept;

    @Column(name = "F02_MNO")
    private String custodian;

    @Column(name = "F02_FLOOR")
    private String location;

    @Column(name = "F02_DATE")
    private LocalDate purchaseDate;

    @Column(name = "F02_OYY")
    private String usefulLife;

    @Column(name = "F02_ODATE")
    private LocalDate warrantyDate;

    @Column(name = "F02_PCNAME")
    private String pcName;

    @Column(name = "F02_FILE", length = 4000)
    private String fileDescription;

    @Column(name = "F02_MARK", length = 4000)
    private String remark;

    @Column(name = "F02_PHOTONAME")
    private String photoName;

    @Column(name = "F02_USETYPE")
    private String status;

    @Column(name = "F02_LEASEDEPT")
    private String leaseDept;

    @Column(name = "F02_SIZE")
    private String size;

    @Column(name = "CRUSER")
    private String createdBy;

    @Column(name = "MODUSER")
    private String lastModifiedBy;

    @Column(name = "imgidlist")
    private String imgIdList;

    @Column(name = "F02_CLASSTYPE")
    private String classType;

    @Column(name = "REGIONID")
    private String regionId;

    @Column(name = "RAGICSH", length = 50)
    private String ragicSh;

    @Column(name = "RAGICID", length = 50)
    private String ragicId;

    @Column(name = "CHANGETYPE", length = 50)
    private String changeType;

    @Column(name = "CHANGEDTE")
    private java.time.LocalDateTime changeDte;

    @Column(name = "CHANGEUSER", length = 50)
    private String changeUser;

}
