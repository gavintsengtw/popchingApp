package com.popching.cams.service;

import com.popching.cams.entity.RoleFunction;
import com.popching.cams.repository.RoleFunctionRepository;
import com.popching.cams.repository.RoleRepository;
import com.popching.cams.repository.SystemFunctionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class RoleFunctionService {

    @Autowired
    private RoleFunctionRepository roleFunctionRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private SystemFunctionRepository systemFunctionRepository;

    public List<RoleFunction> searchRoleFunctions(String roleId, String funcId) {
        return roleFunctionRepository.searchMappings(roleId, funcId).stream()
                .map(this::populateTransientFields)
                .collect(Collectors.toList());
    }

    public Optional<RoleFunction> getRoleFunctionById(Long id) {
        return roleFunctionRepository.findById(id).map(this::populateTransientFields);
    }

    public RoleFunction createRoleFunction(RoleFunction roleFunction) {
        // Prevent duplicate mapping for the same role and function
        roleFunctionRepository.findByRoleIdAndFuncId(roleFunction.getRoleId(), roleFunction.getFuncId())
                .ifPresent(existing -> {
                    if (!"Y".equalsIgnoreCase(existing.getDelmark())) {
                        throw new RuntimeException("Group already has this function mapped.");
                    } else {
                        // Update the deleted record instead of creating a new one
                        roleFunction.setId(existing.getId());
                    }
                });

        if (roleFunction.getId() == null) {
            // Identity generation will handle this upon save
        }
        roleFunction.setDelmark("N");
        return populateTransientFields(roleFunctionRepository.save(roleFunction));
    }

    public RoleFunction updateRoleFunction(Long id, RoleFunction roleFunctionDetails) {
        RoleFunction existing = roleFunctionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("RoleFunction not found with id: " + id));

        // ensure uniqueness when updating
        if (!existing.getRoleId().equals(roleFunctionDetails.getRoleId()) ||
                !existing.getFuncId().equals(roleFunctionDetails.getFuncId())) {
            roleFunctionRepository
                    .findByRoleIdAndFuncId(roleFunctionDetails.getRoleId(), roleFunctionDetails.getFuncId())
                    .ifPresent(dup -> {
                        if (!"Y".equalsIgnoreCase(dup.getDelmark())) {
                            throw new RuntimeException("Group already has this function mapped.");
                        }
                    });
        }

        existing.setRoleId(roleFunctionDetails.getRoleId());
        existing.setFuncId(roleFunctionDetails.getFuncId());
        if (roleFunctionDetails.getDelmark() != null) {
            existing.setDelmark(roleFunctionDetails.getDelmark());
        }
        if (roleFunctionDetails.getDelmemo() != null) {
            existing.setDelmemo(roleFunctionDetails.getDelmemo());
        }
        return populateTransientFields(roleFunctionRepository.save(existing));
    }

    public void deleteRoleFunction(Long id) {
        RoleFunction existing = roleFunctionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("RoleFunction not found with id: " + id));
        existing.setDelmark("Y");
        roleFunctionRepository.save(existing);
    }

    private RoleFunction populateTransientFields(RoleFunction rf) {
        if (rf.getRoleId() != null && !rf.getRoleId().isEmpty()) {
            roleRepository.findByGroupId(rf.getRoleId()).ifPresent(role -> rf.setGroupName(role.getName()));
        }

        if (rf.getFuncId() != null && !rf.getFuncId().isEmpty()) {
            systemFunctionRepository.findByFuncId(rf.getFuncId()).ifPresent(func -> rf.setFuncName(func.getName()));

            // Derive parent function ID based on '-' (e.g. fc001-001 -> fc001)
            if (rf.getFuncId().contains("-")) {
                String parentId = rf.getFuncId().split("-")[0];
                rf.setParentFuncId(parentId);
                systemFunctionRepository.findByFuncId(parentId)
                        .ifPresent(parentFunc -> rf.setParentFuncName(parentFunc.getName()));
            } else {
                // If it doesn't contain '-', it might be a top-level function itself or have no
                // parent
                rf.setParentFuncId("");
                rf.setParentFuncName("");
            }
        }
        return rf;
    }
}
