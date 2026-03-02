package com.popching.cams.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "locations")
public class Location extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // e.g., Warehouse A, Project Site B

    private String type; // WAREHOUSE, SITE

    private String address;

    private String area; // e.g., Zone A
    private String shelf; // e.g., Shelf B-01
}
