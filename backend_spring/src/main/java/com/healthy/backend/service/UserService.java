package com.healthy.backend.service;

import com.healthy.backend.entity.User;
import com.healthy.backend.exception.BadRequestException;
import com.healthy.backend.repository.UserRepository;
import com.healthy.backend.security.JwtUtil;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final ObjectProvider<SimpMessagingTemplate> messagingTemplateProvider;

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    public UserService(
            UserRepository userRepository,
            JwtUtil jwtUtil,
            ObjectProvider<SimpMessagingTemplate> messagingTemplateProvider
    ) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.messagingTemplateProvider = messagingTemplateProvider;
    }

    // ================= REGISTRATION =================
    public User registerUser(User user) {

        log.info("Попытка регистрации пользователя: {}", user.getEmail());

        if (userRepository.findByEmail(user.getEmail()).isPresent()) {
            log.warn("Регистрация отклонена — email уже существует: {}", user.getEmail());
            throw new BadRequestException("Пользователь с таким email уже существует");
        }

        if (user.getRole() == null) {
            user.setRole("USER");
            log.debug("Роль по умолчанию назначена USER для {}", user.getEmail());
        }

        User saved = userRepository.save(user);

        log.info("Пользователь успешно зарегистрирован id={} email={}", saved.getId(), saved.getEmail());

        sendWs("Новый пользователь: " + saved.getEmail());

        return saved;
    }

    // ================= LOGIN =================
    public Map<String, String> login(String email, String password) {

        log.info("Попытка входа: {}", email);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("Вход отклонён — пользователь не найден: {}", email);
                    return new BadRequestException("Неверный email или пароль");
                });

        if (!user.getPassword().equals(password)) {
            log.error("Вход отклонён — неверный пароль: {}", email);
            throw new BadRequestException("Неверный email или пароль");
        }

        log.info("Успешный вход пользователя: {}", email);

        sendWs("Пользователь вошёл: " + email);

        String token = jwtUtil.generateToken(email);

        Map<String, String> result = new HashMap<>();
        result.put("token", token);
        result.put("role", user.getRole());

        log.debug("JWT токен выдан пользователю {}", email);

        return result;
    }

    // ================= WEBSOCKET =================
    private void sendWs(String msg) {
        SimpMessagingTemplate messagingTemplate = messagingTemplateProvider.getIfAvailable();
        if (messagingTemplate != null) {
            messagingTemplate.convertAndSend("/topic/updates", msg);
            log.debug("WS уведомление отправлено: {}", msg);
        } else {
            log.debug("WS не подключён, сообщение пропущено: {}", msg);
        }
    }
}
