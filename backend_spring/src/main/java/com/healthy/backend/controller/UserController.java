package com.healthy.backend.controller;

import com.healthy.backend.entity.User;
import com.healthy.backend.exception.BadRequestException;
import com.healthy.backend.security.JwtUtil;
import com.healthy.backend.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    private final UserService userService;
    private final JwtUtil jwtUtil;

    public UserController(UserService userService, JwtUtil jwtUtil) {
        this.userService = userService;
        this.jwtUtil = jwtUtil;
    }

    @GetMapping("/check")
    public ResponseEntity<?> checkToken(@RequestHeader("Authorization") String authHeader) {

        if (!authHeader.startsWith("Bearer ")) {
            throw new BadRequestException("Invalid token format");
        }

        String token = authHeader.replace("Bearer ", "");
        String email = jwtUtil.extractEmail(token);

        return ResponseEntity.ok(Map.of("email", email, "valid", true));
    }

    @PostMapping("/register")
    public User register(@RequestBody User user) {
        return userService.registerUser(user);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User user) {

        String token = userService.login(user.getEmail(), user.getPassword()).toString();

        return ResponseEntity.ok(Map.of("token", token));
    }
}
