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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "deptid")
    private Department department;

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

    public boolean isEnabled() {
        return !"Y".equalsIgnoreCase(closemark);
    }
}
