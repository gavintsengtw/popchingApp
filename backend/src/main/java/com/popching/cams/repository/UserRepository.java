package com.popching.cams.repository;

import com.popching.cams.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByUsername(String username);

    Boolean existsByUsername(String username);

    Boolean existsByEmail(String email);

    @Query("SELECT DISTINCT u FROM User u " +
            "LEFT JOIN u.departments d " +
            "WHERE (:keyword IS NULL OR :keyword = '' OR " +
            "       LOWER(u.id) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "       LOWER(u.username) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "       LOWER(u.fullName) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND (:deptId IS NULL OR :deptId = '' OR d.id = :deptId) " +
            "AND (:groupId IS NULL OR :groupId = '' OR u.username IN (SELECT ug.userId FROM UserGroup ug WHERE ug.groupId = :groupId))")
    List<User> searchUsers(@Param("keyword") String keyword,
            @Param("deptId") String deptId,
            @Param("groupId") String groupId);
}
