package com.popching.cams;

import com.popching.cams.entity.Role;
import com.popching.cams.repository.RoleRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    private final RoleRepository roleRepository;

    public DataInitializer(RoleRepository roleRepository) {
        this.roleRepository = roleRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        if (!roleRepository.existsByGroupId("admin")) {
            Role adminRole = new Role();
            adminRole.setGroupId("admin");
            adminRole.setName("System Administrator");
            adminRole.setAdminMark("Y");
            roleRepository.save(adminRole);
        }

        if (!roleRepository.existsByGroupId("user")) {
            Role userRole = new Role();
            userRole.setGroupId("user");
            userRole.setName("Regular User");
            userRole.setAdminMark("N");
            roleRepository.save(userRole);
        }
    }
}
