package com.popching.cams.repository;

import com.popching.cams.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RoleRepository extends JpaRepository<Role, Integer> {
    Optional<Role> findByName(String name);

    Optional<Role> findByGroupId(String groupId);

    boolean existsByGroupId(String groupId);
}
