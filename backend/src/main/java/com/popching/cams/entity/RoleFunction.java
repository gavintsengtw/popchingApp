package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "fixUserFunc")
@AttributeOverrides({
        @AttributeOverride(name = "createdAt", column = @Column(name = "crdte")),
        @AttributeOverride(name = "updatedAt", column = @Column(name = "moddte")),
        @AttributeOverride(name = "createdBy", column = @Column(name = "cruser")),
        @AttributeOverride(name = "lastModifiedBy", column = @Column(name = "moduser"))
})
public class RoleFunction extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "uid")
    private Long id;

    @Column(name = "groupid", nullable = false)
    private String roleId;

    @Column(name = "funcid", nullable = false)
    private String funcId;

    @Column(name = "delmark", length = 1)
    private String delmark;

    @Column(name = "delmemo")
    private String delmemo;

    @Transient
    private String groupName;

    @Transient
    private String funcName;

    @Transient
    private String parentFuncId;

    @Transient
    private String parentFuncName;

    public boolean isDeleted() {
        return "Y".equalsIgnoreCase(delmark);
    }
}
