package com.healthy.backend.service;

import com.healthy.backend.entity.User;
import com.healthy.backend.repository.UserRepository;
import com.healthy.backend.security.JwtUtil;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final ObjectProvider<SimpMessagingTemplate> messagingTemplateProvider;

    public UserService(
            UserRepository userRepository,
            JwtUtil jwtUtil,
            ObjectProvider<SimpMessagingTemplate> messagingTemplateProvider
    ) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.messagingTemplateProvider = messagingTemplateProvider;
    }

    // ✅ регистрация
    public User registerUser(User user) {

        if (userRepository.findByEmail(user.getEmail()).isPresent()) {
            throw new RuntimeException("Пользователь с таким email уже существует");
        }

        if (user.getRole() == null) {
            user.setRole("USER");
        }

        User saved = userRepository.save(user);

        sendWs("Новый пользователь: " + saved.getEmail());

        return saved;
    }

    // ✅ логин с ролью
    public Map<String, String> login(String email, String password) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Неверный email или пароль"));

        if (!user.getPassword().equals(password)) {
            throw new RuntimeException("Неверный email или пароль");
        }

        sendWs("Пользователь вошёл: " + email);

        String token = jwtUtil.generateToken(email);

        Map<String, String> result = new HashMap<>();
        result.put("token", token);
        result.put("role", user.getRole());

        return result;
    }

    private void sendWs(String msg) {
        SimpMessagingTemplate messagingTemplate = messagingTemplateProvider.getIfAvailable();
        if (messagingTemplate != null) {
            messagingTemplate.convertAndSend("/topic/updates", msg);
        }
    }
}
