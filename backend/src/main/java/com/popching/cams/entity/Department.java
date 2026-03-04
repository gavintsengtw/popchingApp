package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
@Entity
@Table(name = "baccount_DEPT_BAS")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Department {

    @Id
    @Column(name = "DEP_NO", length = 50)
    private String id;

    @Column(name = "DEP_NAME", nullable = false)
    private String name;

    @Column(name = "PARENT_NO")
    private String parentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PARENT_NO", insertable = false, updatable = false)
    @org.hibernate.annotations.NotFound(action = org.hibernate.annotations.NotFoundAction.IGNORE)
    @com.fasterxml.jackson.annotation.JsonBackReference
    @lombok.EqualsAndHashCode.Exclude
    @lombok.ToString.Exclude
    private Department parent;

    @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL)
    @com.fasterxml.jackson.annotation.JsonManagedReference
    @lombok.EqualsAndHashCode.Exclude
    @lombok.ToString.Exclude
    private List<Department> children = new ArrayList<>();

    @Column(name = "DEP_CHIEF")
    private String managerName;

    @Column(name = "closemark")
    private String closemark;

    @Column(name = "cruser")
    private String createdBy;

    @Column(name = "crdte")
    private String createdAt;

    @Column(name = "moduser")
    private String lastModifiedBy;

    @Column(name = "moddte")
    private String updatedAt;

    public boolean isEnabled() {
        return !"Y".equalsIgnoreCase(closemark);
    }
}
