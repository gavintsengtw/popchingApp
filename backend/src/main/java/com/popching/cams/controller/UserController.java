package com.popching.cams.controller;

import com.popching.cams.entity.User;
import com.popching.cams.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public List<User> getAllUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String deptId,
            @RequestParam(required = false) String groupId) {
        if ((keyword != null && !keyword.isEmpty()) ||
                (deptId != null && !deptId.isEmpty()) ||
                (groupId != null && !groupId.isEmpty())) {
            return userService.searchUsers(keyword, deptId, groupId);
        }
        return userService.getAllUsers();
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<User> getUserById(@PathVariable String id) {
        User user = userService.getUserById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok().body(user);
    }

    @GetMapping("/profile")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<User> getMyProfile(org.springframework.security.core.Authentication authentication) {
        User user = userService.getUserByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(user);
    }

    @PutMapping("/profile")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<User> updateMyProfile(org.springframework.security.core.Authentication authentication,
            @RequestBody User userDetails) {
        User updatedUser = userService.updateProfile(authentication.getName(), userDetails);
        return ResponseEntity.ok(updatedUser);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_ADD')")
    public User createUser(@RequestBody User user) {
        return userService.createUser(user);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT') or authentication.name == #id")
    public ResponseEntity<User> updateUser(
            @PathVariable String id,
            @RequestBody User userDetails) {
        User updatedUser = userService.updateUser(id, userDetails);
        return ResponseEntity.ok(updatedUser);
    }

    @PostMapping("/{id}/reset-password")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_EDIT')")
    public ResponseEntity<?> resetPassword(@PathVariable String id) {
        userService.resetPassword(id);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('PERM_DELETE')")
    public ResponseEntity<?> deleteUser(@PathVariable String id) {
        userService.deleteUser(id);
        return ResponseEntity.ok().build();
    }
}
