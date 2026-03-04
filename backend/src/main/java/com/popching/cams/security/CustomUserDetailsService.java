package com.popching.cams.security;

import com.popching.cams.entity.User;
import com.popching.cams.repository.UserRepository;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

import com.popching.cams.repository.UserGroupRepository;
import com.popching.cams.entity.UserGroup;
import java.util.List;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final UserGroupRepository userGroupRepository;
    private final com.popching.cams.repository.RoleRepository roleRepository;

    public CustomUserDetailsService(UserRepository userRepository, UserGroupRepository userGroupRepository,
            com.popching.cams.repository.RoleRepository roleRepository) {
        this.userRepository = userRepository;
        this.userGroupRepository = userGroupRepository;
        this.roleRepository = roleRepository;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String usernameOrEmail) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(usernameOrEmail)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "User not found with username or email: " + usernameOrEmail));

        Set<GrantedAuthority> authorities = new java.util.HashSet<>();

        List<UserGroup> userGroups = userGroupRepository.findByUserId(user.getUsername());

        for (UserGroup ug : userGroups) {
            String roleName = ug.getGroupId().trim();
            if (!roleName.toUpperCase().startsWith("ROLE_")) {
                roleName = "ROLE_" + roleName.toUpperCase();
            }
            authorities.add(new SimpleGrantedAuthority(roleName));

            // Fetch group_crud to check permissions
            roleRepository.findByGroupId(ug.getGroupId()).ifPresent(role -> {
                if ("Y".equalsIgnoreCase(role.getNewMark()) || "1".equals(role.getNewMark()))
                    authorities.add(new SimpleGrantedAuthority("PERM_ADD"));
                if ("Y".equalsIgnoreCase(role.getModMark()) || "1".equals(role.getModMark()))
                    authorities.add(new SimpleGrantedAuthority("PERM_EDIT"));
                if ("Y".equalsIgnoreCase(role.getDeleteMark()) || "1".equals(role.getDeleteMark()))
                    authorities.add(new SimpleGrantedAuthority("PERM_DELETE"));
                if ("Y".equalsIgnoreCase(role.getAdminMark()) || "1".equals(role.getAdminMark()))
                    authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
            });
        }

        // Only use legacy comma-separated string if the user has no defined groups in
        // baccount_group
        if (authorities.isEmpty() && user.getGrpadilities() != null && !user.getGrpadilities().trim().isEmpty()) {
            String[] roles = user.getGrpadilities().split(",");
            for (String role : roles) {
                String roleName = role.trim();
                if (!roleName.toUpperCase().startsWith("ROLE_")) {
                    roleName = "ROLE_" + roleName.toUpperCase();
                }
                authorities.add(new SimpleGrantedAuthority(roleName));
            }
        }

        return new org.springframework.security.core.userdetails.User(user.getUsername(),
                user.getPassword(),
                user.isEnabled(),
                true,
                true,
                true,
                authorities);
    }
}
