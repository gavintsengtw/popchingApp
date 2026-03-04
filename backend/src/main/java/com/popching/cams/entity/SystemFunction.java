package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "fixFunc")
@AttributeOverrides({
        @AttributeOverride(name = "createdAt", column = @Column(name = "crdte")),
        @AttributeOverride(name = "updatedAt", column = @Column(name = "moddte")),
        @AttributeOverride(name = "createdBy", column = @Column(name = "cruser")),
        @AttributeOverride(name = "lastModifiedBy", column = @Column(name = "moduser"))
})
public class SystemFunction extends BaseEntity {

    @Id
    @Column(name = "uid", length = 50)
    private String id;

    @Column(name = "funcid", nullable = false)
    private String funcId; // E.g., Module / Feature Code

    @Column(name = "funcName", nullable = false)
    private String name;

    @Column(name = "funcberf")
    private String description;

    @Column(name = "funcIcon")
    private String icon;

    @Column(name = "funcLink")
    private String routeLink;

    @Column(name = "delmark", length = 1)
    private String delmark;

    @Column(name = "delmemo")
    private String delmemo;

    public boolean isDeleted() {
        return "Y".equalsIgnoreCase(delmark);
    }
}
