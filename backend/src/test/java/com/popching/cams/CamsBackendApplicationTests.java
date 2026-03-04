package com.popching.cams;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Autowired;

@SpringBootTest
class CamsBackendApplicationTests {

	@Autowired
	private com.popching.cams.service.UserService userService;

	@Test
	@org.springframework.transaction.annotation.Transactional
	@org.springframework.test.annotation.Rollback(false)
	void testAssignAdmin() {
		java.util.List<com.popching.cams.entity.User> users = userService.getAllUsers();
		for (com.popching.cams.entity.User u : users) {
			if (u.getUsername().equals("admin_test1")) {
				System.out.println("Found test admin, prior roles: " + u.getGrpadilities());
				u.setGrpadilities("ROLE_ADMIN");
				System.out.println("Assigned ROLE_ADMIN");
			}
		}
	}
}
