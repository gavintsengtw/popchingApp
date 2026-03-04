package com.popching.cams.service;

import com.popching.cams.entity.SystemFunction;
import com.popching.cams.repository.SystemFunctionRepository;
import com.popching.cams.entity.RoleFunction;
import com.popching.cams.entity.UserGroup;
import com.popching.cams.repository.RoleFunctionRepository;
import com.popching.cams.repository.UserGroupRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class SystemFunctionService {

    @Autowired
    private SystemFunctionRepository systemFunctionRepository;

    @Autowired
    private UserGroupRepository userGroupRepository;

    @Autowired
    private RoleFunctionRepository roleFunctionRepository;

    public List<SystemFunction> getAllFunctions() {
        return systemFunctionRepository.findAll().stream()
                .filter(f -> !f.isDeleted())
                .collect(Collectors.toList());
    }

    public Optional<SystemFunction> getFunctionById(String id) {
        return systemFunctionRepository.findById(id).filter(f -> !f.isDeleted());
    }

    public List<SystemFunction> getMyMenu(String username, boolean isAdmin) {
        if (isAdmin) {
            return getAllFunctions(); // admin has access to everything
        }

        // 1. Get user's active groups
        List<String> userRoles = userGroupRepository.findByUserId(username).stream()
                .map(UserGroup::getGroupId)
                .collect(Collectors.toList());

        if (userRoles.isEmpty()) {
            return List.of(); // No functions for users without a role
        }

        // 2. Fetch all role-function configurations based on their roles
        List<RoleFunction> allowedMappings = roleFunctionRepository.findActiveByRoleIds(userRoles);

        // 3. Extract funcIds and also compute parent funcIds required to render the
        // sidebar hierarchy
        Set<String> renderFuncIds = new HashSet<>();
        for (RoleFunction rf : allowedMappings) {
            String fId = rf.getFuncId();
            if (fId != null && !fId.isEmpty()) {
                renderFuncIds.add(fId);
                // Extract parent if there is a hyphen (e.g. fc001-001 -> fc001)
                if (fId.contains("-")) {
                    String parentId = fId.split("-")[0];
                    renderFuncIds.add(parentId);
                }
            }
        }

        if (renderFuncIds.isEmpty()) {
            return List.of();
        }

        // 4. Retrieve those functions and filter out anything marked deleted
        return systemFunctionRepository.findByFuncIdIn(List.copyOf(renderFuncIds)).stream()
                .filter(f -> !f.isDeleted())
                .collect(Collectors.toList());
    }

    public SystemFunction createFunction(SystemFunction function) {
        if (systemFunctionRepository.existsById(function.getId())) {
            throw new RuntimeException("Function already exists with ID: " + function.getId());
        }
        return systemFunctionRepository.save(function);
    }

    public SystemFunction updateFunction(String id, SystemFunction functionDetails) {
        SystemFunction function = systemFunctionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Function not found"));
        function.setFuncId(functionDetails.getFuncId());
        function.setName(functionDetails.getName());
        function.setDescription(functionDetails.getDescription());
        function.setIcon(functionDetails.getIcon());
        function.setRouteLink(functionDetails.getRouteLink());
        return systemFunctionRepository.save(function);
    }

    public void deleteFunction(String id) {
        SystemFunction function = systemFunctionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Function not found"));
        function.setDelmark("Y");
        systemFunctionRepository.save(function);
    }
}
