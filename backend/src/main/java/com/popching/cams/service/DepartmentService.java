package com.popching.cams.service;

import com.popching.cams.entity.Department;
import com.popching.cams.repository.DepartmentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class DepartmentService {

    @Autowired
    private DepartmentRepository departmentRepository;

    public List<Department> getAllDepartments() {
        return departmentRepository.findAll().stream()
                .filter(Department::isEnabled)
                .collect(java.util.stream.Collectors.toList());
    }

    public Optional<Department> getDepartmentById(String id) {
        return departmentRepository.findById(id);
    }

    public Department createDepartment(Department department) {
        if (department.getId() != null && departmentRepository.existsById(department.getId())) {
            throw new RuntimeException("Department with this ID already exists: " + department.getId());
        }
        if (department.getParentId() == null || department.getParentId().isEmpty()) {
            department.setParentId("0");
        }
        return departmentRepository.save(department);
    }

    public Department updateDepartment(String id, Department departmentDetails) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Department not found with id: " + id));
        department.setName(departmentDetails.getName());
        department.setManagerName(departmentDetails.getManagerName());

        String newParentId = departmentDetails.getParentId();
        if (newParentId == null || newParentId.isEmpty()) {
            newParentId = "0";
        }
        department.setParentId(newParentId);
        if (departmentDetails.getClosemark() != null) {
            department.setClosemark(departmentDetails.getClosemark());
        } else {
            department.setClosemark("N");
        }
        return departmentRepository.save(department);
    }

    public void deleteDepartment(String id) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Department not found with id: " + id));
        department.setClosemark("Y");
        departmentRepository.save(department);
    }
}
