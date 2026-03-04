package com.popching.cams.service;

import com.popching.cams.entity.Role;
import com.popching.cams.repository.RoleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class RoleService {

    @Autowired
    private RoleRepository roleRepository;

    public List<Role> getAllRoles() {
        // Exclude logically deleted roles "Y"
        return roleRepository.findAll().stream()
                .filter(role -> !role.isDeleted())
                .collect(Collectors.toList());
    }

    public Optional<Role> getRoleById(Integer uid) {
        return roleRepository.findById(uid).filter(role -> !role.isDeleted());
    }

    public Role createRole(Role role) {
        if (roleRepository.existsByGroupId(role.getGroupId())) {
            throw new RuntimeException("Role with this Group ID already exists: " + role.getGroupId());
        }
        return roleRepository.save(role);
    }

    public Role updateRole(Integer uid, Role roleDetails) {
        Role role = roleRepository.findById(uid)
                .orElseThrow(() -> new RuntimeException("Role not found with UID: " + uid));

        // Check uniqueness if groupId changes
        if (!role.getGroupId().equals(roleDetails.getGroupId())
                && roleRepository.existsByGroupId(roleDetails.getGroupId())) {
            throw new RuntimeException("Role with this Group ID already exists: " + roleDetails.getGroupId());
        }

        role.setGroupId(roleDetails.getGroupId());
        role.setName(roleDetails.getName());
        role.setAdminMark(roleDetails.getAdminMark());
        role.setNewMark(roleDetails.getNewMark());
        role.setModMark(roleDetails.getModMark());
        role.setDeleteMark(roleDetails.getDeleteMark());
        role.setSerchMark(roleDetails.getSerchMark());
        role.setLockMark(roleDetails.getLockMark());
        role.setUnLockMark(roleDetails.getUnLockMark());

        return roleRepository.save(role);
    }

    public void deleteRole(Integer uid) {
        Role role = roleRepository.findById(uid)
                .orElseThrow(() -> new RuntimeException("Role not found with UID: " + uid));
        role.setDelmark("Y");
        roleRepository.save(role);
    }
}
