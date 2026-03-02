package com.popching.cams.payload;

import lombok.Data;

@Data
public class SignUpRequest {
    private String name;
    private String username;
    private String email;
    private String password;
    private String employeeId;
}
