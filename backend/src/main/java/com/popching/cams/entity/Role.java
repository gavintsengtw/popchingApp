package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "group_crud")
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "UID")
    private Integer uid;

    @Column(name = "groupid", length = 50, unique = true, nullable = false)
    private String groupId;

    @Column(name = "groupname", nullable = false)
    private String name;

    @Column(name = "adminMark", length = 1)
    private String adminMark;

    @Column(name = "newMark", length = 1)
    private String newMark;

    @Column(name = "modMark", length = 1)
    private String modMark;

    @Column(name = "deleteMark", length = 1)
    private String deleteMark;

    @Column(name = "serchMark", length = 1)
    private String serchMark;

    @Column(name = "lockMark", length = 1)
    private String lockMark;

    @Column(name = "unLockMark", length = 1)
    private String unLockMark;

    @Column(name = "crduser")
    private String createdBy;

    @Column(name = "crddte")
    private String createdAt;

    @Column(name = "mdfuser")
    private String lastModifiedBy;

    @Column(name = "mdfdte")
    private String updatedAt;

    @Column(name = "delmark", length = 1)
    private String delmark;

    public boolean isDeleted() {
        return "Y".equalsIgnoreCase(delmark);
    }
}
