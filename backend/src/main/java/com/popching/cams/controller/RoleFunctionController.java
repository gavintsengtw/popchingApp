package com.popching.cams.controller;

import com.popching.cams.entity.RoleFunction;
import com.popching.cams.service.RoleFunctionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/role-functions")
public class RoleFunctionController {

    @Autowired
    private RoleFunctionService roleFunctionService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public List<RoleFunction> searchRoleFunctions(
            @RequestParam(required = false) String roleId,
            @RequestParam(required = false) String funcId) {
        return roleFunctionService.searchRoleFunctions(roleId, funcId);
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<RoleFunction> getRoleFunctionById(@PathVariable Long id) {
        RoleFunction rf = roleFunctionService.getRoleFunctionById(id)
                .orElseThrow(() -> new RuntimeException("RoleFunction not found"));
        return ResponseEntity.ok().body(rf);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_ADD')")
    public RoleFunction createRoleFunction(@RequestBody RoleFunction roleFunction) {
        return roleFunctionService.createRoleFunction(roleFunction);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<RoleFunction> updateRoleFunction(
            @PathVariable Long id,
            @RequestBody RoleFunction roleFunctionDetails) {
        RoleFunction updated = roleFunctionService.updateRoleFunction(id, roleFunctionDetails);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_DELETE')")
    public ResponseEntity<?> deleteRoleFunction(@PathVariable Long id) {
        roleFunctionService.deleteRoleFunction(id);
        return ResponseEntity.ok().build();
    }
}
