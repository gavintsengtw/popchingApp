package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "baccount")
@AttributeOverrides({
        @AttributeOverride(name = "createdAt", column = @Column(name = "crdte")),
        @AttributeOverride(name = "updatedAt", column = @Column(name = "moddte"))
})
public class User extends BaseEntity {

    @Id
    @Column(name = "Badgenumber", length = 50)
    private String id; // Badgenumber

    @Column(name = "account", nullable = false, unique = true)
    private String username;

    @Column(name = "pwd", nullable = false)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private String password;

    @Column(name = "name", nullable = false)
    private String fullName;

    @Column(name = "agent")
    private String agent;

    @Column(name = "email")
    private String email;

    @Column(name = "cellphone")
    private String cellphone;

    @Column(name = "closemark")
    private String closemark; // 'Y' = closed?, used for enabled/disabled

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "baccount_DEPT", joinColumns = @JoinColumn(name = "ID", referencedColumnName = "account"), inverseJoinColumns = @JoinColumn(name = "DEP_NO"))
    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "children", "parent" })
    @lombok.EqualsAndHashCode.Exclude
    @lombok.ToString.Exclude
    private java.util.Set<Department> departments = new java.util.HashSet<>();

    @Column(name = "cruser")
    private String createdBy;

    @Column(name = "moduser")
    private String lastModifiedBy;

    @Column(name = "grpadilities")
    private String grpadilities; // Roles/Abilities string

    @Column(name = "userDept")
    private String userDept;

    @Column(name = "IsDefaultPassword")
    private Integer isDefaultPassword; // 1 = default password, 0 = changed

    @Transient
    private java.util.List<String> roleIds;

    @Transient
    private java.util.List<String> roleNames;

    public boolean isEnabled() {
        return !"Y".equalsIgnoreCase(closemark);
    }
}
