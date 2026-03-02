package com.popching.cams;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class CamsBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(CamsBackendApplication.class, args);
	}

}
