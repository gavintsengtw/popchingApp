package com.popching.cams.repository;

import com.popching.cams.entity.UserGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserGroupRepository extends JpaRepository<UserGroup, String> {
    List<UserGroup> findByUserId(String userId);
}
