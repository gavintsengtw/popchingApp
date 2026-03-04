package com.popching.cams.controller;

import com.popching.cams.entity.SystemFunction;
import com.popching.cams.entity.RoleFunction;
import com.popching.cams.service.SystemFunctionService;
import com.popching.cams.repository.RoleFunctionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/functions")
public class SystemFunctionController {

    @Autowired
    private SystemFunctionService systemFunctionService;

    @Autowired
    private RoleFunctionRepository roleFunctionRepository;

    @GetMapping("/my-menu")
    public List<SystemFunction> getMyMenu() {
        org.springframework.security.core.Authentication authentication = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication();
        String username = authentication.getName();
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        return systemFunctionService.getMyMenu(username, isAdmin);
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public List<SystemFunction> getAllFunctions() {
        return systemFunctionService.getAllFunctions();
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<SystemFunction> getFunctionById(@PathVariable String id) {
        SystemFunction function = systemFunctionService.getFunctionById(id)
                .orElseThrow(() -> new RuntimeException("Function not found"));
        return ResponseEntity.ok().body(function);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_ADD')")
    public SystemFunction createFunction(@RequestBody SystemFunction function) {
        return systemFunctionService.createFunction(function);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<SystemFunction> updateFunction(
            @PathVariable String id,
            @RequestBody SystemFunction functionDetails) {
        SystemFunction updatedFunction = systemFunctionService.updateFunction(id, functionDetails);
        return ResponseEntity.ok(updatedFunction);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_DELETE')")
    public ResponseEntity<?> deleteFunction(@PathVariable String id) {
        systemFunctionService.deleteFunction(id);
        return ResponseEntity.ok().build();
    }

    // Assign Role to Function API
    @GetMapping("/role/{roleId}")
    @PreAuthorize("isAuthenticated()")
    public List<RoleFunction> getRoleFunctions(@PathVariable String roleId) {
        return roleFunctionRepository.findByRoleId(roleId);
    }
}
