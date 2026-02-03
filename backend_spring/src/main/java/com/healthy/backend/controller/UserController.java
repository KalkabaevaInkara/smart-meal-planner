package com.healthy.backend.controller;

import com.healthy.backend.entity.User;
import com.healthy.backend.service.UserService;
import com.healthy.backend.security.JwtUtil;
import org.springframework.http.HttpStatus;
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

    // ✅ Проверка токена
    @GetMapping("/check")
    public ResponseEntity<?> checkToken(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        String email = jwtUtil.extractEmail(token);
        return ResponseEntity.ok(Map.of("email", email, "valid", true));
    }

    // ✅ Регистрация
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            User newUser = userService.registerUser(user);
            return ResponseEntity.ok(newUser);
        } catch (RuntimeException e) {
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ✅ Вход
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User user) {
        try {
            String token = userService.login(user.getEmail(), user.getPassword()).toString();
            return ResponseEntity.ok(Map.of("token", token));
        } catch (RuntimeException e) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
