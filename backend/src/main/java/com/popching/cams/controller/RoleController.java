package com.popching.cams.controller;

import com.popching.cams.entity.Role;
import com.popching.cams.service.RoleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
public class RoleController {

    @Autowired
    private RoleService roleService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public List<Role> getAllRoles() {
        return roleService.getAllRoles();
    }

    @GetMapping("/{uid}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Role> getRoleById(@PathVariable Integer uid) {
        Role role = roleService.getRoleById(uid)
                .orElseThrow(() -> new RuntimeException("Role not found"));
        return ResponseEntity.ok().body(role);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_ADD')")
    public Role createRole(@RequestBody Role role) {
        return roleService.createRole(role);
    }

    @PutMapping("/{uid}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<Role> updateRole(
            @PathVariable Integer uid,
            @RequestBody Role roleDetails) {
        Role updatedRole = roleService.updateRole(uid, roleDetails);
        return ResponseEntity.ok(updatedRole);
    }

    @DeleteMapping("/{uid}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_DELETE')")
    public ResponseEntity<?> deleteRole(@PathVariable Integer uid) {
        roleService.deleteRole(uid);
        return ResponseEntity.ok().build();
    }
}
