package com.popching.cams.controller;

import com.popching.cams.entity.User;
import com.popching.cams.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/test-users")
public class TestUserController {

    @Autowired
    private UserService userService;

    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @Autowired
    private com.popching.cams.service.SystemFunctionService systemFunctionService;

    @Autowired
    private com.popching.cams.repository.UserGroupRepository userGroupRepository;

    @Autowired
    private com.popching.cams.security.CustomUserDetailsService customUserDetailsService;

    @GetMapping("/gavintseng-debug")
    public java.util.Map<String, Object> debugGavinTseng() {
        java.util.Map<String, Object> debugInfo = new java.util.HashMap<>();

        try {
            org.springframework.security.core.userdetails.UserDetails userDetails = customUserDetailsService
                    .loadUserByUsername("gavintseng");
            debugInfo.put("authorities", userDetails.getAuthorities().stream().map(a -> a.getAuthority()).toArray());

            boolean isAdmin = userDetails.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
            debugInfo.put("isAdmin", isAdmin);

            debugInfo.put("userGroups", userGroupRepository.findByUserId("gavintseng"));

            debugInfo.put("myMenu_admin_false", systemFunctionService.getMyMenu("gavintseng", false));
            debugInfo.put("myMenu_admin_true", systemFunctionService.getMyMenu("gavintseng", true));
        } catch (Exception e) {
            debugInfo.put("error", e.getMessage());
        }

        return debugInfo;
    }
}
