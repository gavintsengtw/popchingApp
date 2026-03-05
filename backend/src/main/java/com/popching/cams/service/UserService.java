package com.popching.cams.service;

import com.popching.cams.entity.User;
import com.popching.cams.repository.UserRepository;
import com.popching.cams.entity.UserGroup;
import com.popching.cams.repository.UserGroupRepository;
import com.popching.cams.entity.Role;
import com.popching.cams.repository.RoleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private UserGroupRepository userGroupRepository;

    @Autowired
    private RoleRepository roleRepository;

    public List<User> searchUsers(String keyword, String deptId, String groupId) {
        List<User> users = userRepository.searchUsers(keyword, deptId, groupId);
        return users.stream().map(this::populateRoles).collect(Collectors.toList());
    }

    public List<User> getAllUsers() {
        return userRepository.findAll().stream().map(this::populateRoles).collect(Collectors.toList());
    }

    private User populateRoles(User user) {
        List<UserGroup> userGroups = userGroupRepository.findByUserId(user.getUsername());
        List<String> roleIds = userGroups.stream().map(UserGroup::getGroupId).collect(Collectors.toList());
        List<String> roleNames = roleIds.stream()
                .map(id -> roleRepository.findByGroupId(id).map(Role::getName).orElse(id))
                .collect(Collectors.toList());
        user.setRoleIds(roleIds);
        user.setRoleNames(roleNames);
        return user;
    }

    public Optional<User> getUserById(String id) {
        return userRepository.findById(id).map(this::populateRoles);
    }

    public Optional<User> getUserByUsername(String username) {
        return userRepository.findByUsername(username).map(this::populateRoles);
    }

    public User createUser(User user) {
        if (userRepository.existsByUsername(user.getUsername())) {
            throw new RuntimeException("Username already exists");
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        if (user.getClosemark() == null) {
            user.setClosemark("N");
        }
        user.setIsDefaultPassword(1); // Set default password flag for new users
        User savedUser = userRepository.save(user);

        if (user.getRoleIds() != null) {
            for (String roleId : user.getRoleIds()) {
                UserGroup ug = new UserGroup();
                ug.setId(UUID.randomUUID().toString());
                ug.setUserId(savedUser.getUsername());
                ug.setGroupId(roleId);
                userGroupRepository.save(ug);
            }
        }

        return populateRoles(savedUser);
    }

    public User updateUser(String id, User userDetails) {
        System.out.println("DEBUG: Updating user id=" + id + ", received closemark=" + userDetails.getClosemark());
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found: " + id));
        System.out.println("DEBUG: Old closemark=" + user.getClosemark());
        user.setFullName(userDetails.getFullName());
        user.setEmail(userDetails.getEmail());
        user.setCellphone(userDetails.getCellphone());
        if (userDetails.getDepartments() != null) {
            user.getDepartments().clear();
            user.getDepartments().addAll(userDetails.getDepartments());
        }
        if (userDetails.getClosemark() != null) {
            user.setClosemark(userDetails.getClosemark());
        }
        // Only update password if provided
        if (userDetails.getPassword() != null && !userDetails.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(userDetails.getPassword()));
        }

        user.setAgent(userDetails.getAgent());

        User updatedUser = userRepository.save(user);

        if (userDetails.getRoleIds() != null) {
            List<UserGroup> existingGroups = userGroupRepository.findByUserId(updatedUser.getUsername());
            userGroupRepository.deleteAll(existingGroups);
            for (String roleId : userDetails.getRoleIds()) {
                UserGroup ug = new UserGroup();
                ug.setId(UUID.randomUUID().toString());
                ug.setUserId(updatedUser.getUsername());
                ug.setGroupId(roleId);
                userGroupRepository.save(ug);
            }
        }

        return populateRoles(updatedUser);
    }

    public User updateProfile(String username, User userDetails) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setEmail(userDetails.getEmail());
        user.setCellphone(userDetails.getCellphone());
        user.setAgent(userDetails.getAgent());
        if (userDetails.getPassword() != null && !userDetails.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(userDetails.getPassword()));
        }
        return populateRoles(userRepository.save(user));
    }

    public void resetPassword(String id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPassword(passwordEncoder.encode("123456"));
        user.setIsDefaultPassword(1);
        userRepository.save(user);
    }

    public void deleteUser(String id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setClosemark("Y");
        userRepository.save(user);
    }
}
