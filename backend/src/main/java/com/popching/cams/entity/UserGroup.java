package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "userGroup")
public class UserGroup {

    @Id
    @Column(name = "uid", length = 50)
    private String id;

    @Column(name = "userid", nullable = false)
    private String userId;

    @Column(name = "groupid", nullable = false)
    private String groupId;
}
