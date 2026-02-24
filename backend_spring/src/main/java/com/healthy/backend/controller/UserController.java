package com.healthy.backend.controller;

import com.healthy.backend.entity.User;
import com.healthy.backend.exception.BadRequestException;
import com.healthy.backend.security.JwtUtil;
import com.healthy.backend.service.UserService;
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

    // ================= REGISTER =================
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        return ResponseEntity.ok(userService.registerUser(user));
    }

    // ================= LOGIN =================
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User user) {
        return ResponseEntity.ok(
                userService.login(user.getEmail(), user.getPassword())
        );
    }

    // ================= CHECK TOKEN =================
    @GetMapping("/check")
    public ResponseEntity<?> checkToken(@RequestHeader("Authorization") String authHeader) {

        if (!authHeader.startsWith("Bearer ")) {
            throw new BadRequestException("Invalid token format");
        }

        String token = authHeader.replace("Bearer ", "");
        String email = jwtUtil.extractEmail(token);

        return ResponseEntity.ok(Map.of(
                "email", email,
                "valid", true
        ));
    }

    // ================= RESET PASSWORD (по email - твой метод) =================
    @PutMapping("/reset-password")
    public ResponseEntity<?> resetPassword(
            @RequestParam String email,
            @RequestParam String newPassword
    ) {
        userService.resetPassword(email, newPassword);
        return ResponseEntity.ok(Map.of("message", "Пароль обновлён"));
    }

    // ================= REQUEST RESET TOKEN =================
    @PostMapping("/request-reset")
    public ResponseEntity<?> requestReset(@RequestBody Map<String, String> body) {

        String email = body.get("email");

        if (email == null || email.isBlank()) {
            throw new BadRequestException("Email обязателен");
        }

        userService.requestPasswordReset(email);

        return ResponseEntity.ok(Map.of(
                "message", "Reset token создан (смотри лог сервера)"
        ));
    }

    // ================= RESET PASSWORD BY TOKEN =================
    @PutMapping("/reset-password-by-token")
    public ResponseEntity<?> resetByToken(
            @RequestParam String token,
            @RequestParam String newPassword
    ) {
        userService.resetPasswordByToken(token, newPassword);
        return ResponseEntity.ok(Map.of(
                "message", "Пароль успешно обновлён"
        ));
    }
}