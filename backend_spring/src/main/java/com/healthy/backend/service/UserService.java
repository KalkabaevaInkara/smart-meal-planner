package com.healthy.backend.service;

import com.healthy.backend.entity.User;
import com.healthy.backend.exception.BadRequestException;
import com.healthy.backend.exception.NotFoundException;
import com.healthy.backend.repository.UserRepository;
import com.healthy.backend.security.JwtUtil;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class UserService {

    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final ObjectProvider<SimpMessagingTemplate> messagingTemplateProvider;

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    public UserService(
            UserRepository userRepository,
            JwtUtil jwtUtil,
            ObjectProvider<SimpMessagingTemplate> messagingTemplateProvider,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.messagingTemplateProvider = messagingTemplateProvider;
        this.passwordEncoder = passwordEncoder;
    }

    // ================= REGISTRATION =================
    public Map<String, Object> registerUser(User user) {

        if (userRepository.findByEmail(user.getEmail()).isPresent()) {
            throw new BadRequestException("Пользователь с таким email уже существует");
        }

        if (user.getRole() == null) {
            user.setRole("USER");
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));

        User saved = userRepository.save(user);

        sendWs("Новый пользователь: " + saved.getEmail());

        String token = jwtUtil.generateToken(saved.getEmail());

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("role", saved.getRole());
        response.put("email", saved.getEmail());
        response.put("fullName", saved.getFullName());

        return response;
    }

    // ================= LOGIN =================
    public Map<String, Object> login(String email, String password) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadRequestException("Неверный email или пароль"));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BadRequestException("Неверный email или пароль");
        }

        String token = jwtUtil.generateToken(email);

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("role", user.getRole());
        response.put("email", user.getEmail());
        response.put("fullName", user.getFullName());

        sendWs("Пользователь вошёл: " + email);

        return response;
    }

    // ================= RESET PASSWORD ПО EMAIL (твоя версия оставлена) =================
    public void resetPassword(String email, String newPassword) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    // ================= НОВЫЙ RESET ЧЕРЕЗ ТОКЕН =================
    public void requestPasswordReset(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        String token = UUID.randomUUID().toString();

        user.setResetToken(token);
        user.setResetTokenExpiry(LocalDateTime.now().plusMinutes(30));

        userRepository.save(user);

        log.info("Reset token создан для {}: {}", email, token);
    }

    public void resetPasswordByToken(String token, String newPassword) {

        User user = userRepository.findByResetToken(token)
                .orElseThrow(() -> new BadRequestException("Неверный токен"));

        if (user.getResetTokenExpiry() == null ||
                user.getResetTokenExpiry().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Токен истёк");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        user.setResetToken(null);
        user.setResetTokenExpiry(null);

        userRepository.save(user);
    }

    private void sendWs(String msg) {
        SimpMessagingTemplate messagingTemplate = messagingTemplateProvider.getIfAvailable();
        if (messagingTemplate != null) {
            messagingTemplate.convertAndSend("/topic/updates", msg);
        }
    }
}