package com.popching.cams.repository;

import com.popching.cams.entity.RoleFunction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoleFunctionRepository extends JpaRepository<RoleFunction, Long> {
    List<RoleFunction> findByRoleId(String roleId);

    List<RoleFunction> findByFuncId(String funcId);

    Optional<RoleFunction> findByRoleIdAndFuncId(String roleId, String funcId);

    @Query("SELECT rf FROM RoleFunction rf " +
            "WHERE (:roleId IS NULL OR :roleId = '' OR rf.roleId = :roleId) " +
            "AND (:funcId IS NULL OR :funcId = '' OR rf.funcId = :funcId) " +
            "AND (rf.delmark IS NULL OR rf.delmark != 'Y')")
    List<RoleFunction> searchMappings(@Param("roleId") String roleId, @Param("funcId") String funcId);

    @Query("SELECT rf FROM RoleFunction rf WHERE rf.roleId IN :roleIds AND (rf.delmark IS NULL OR rf.delmark != 'Y')")
    List<RoleFunction> findActiveByRoleIds(@Param("roleIds") List<String> roleIds);
}
