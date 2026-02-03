package com.healthy.backend.controller;

import com.healthy.backend.entity.User;
import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.UserRepository;
import com.healthy.backend.repository.RecipeRepository;
import com.healthy.backend.security.JwtUtil;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final UserRepository userRepository;
    private final RecipeRepository recipeRepository;
    private final JwtUtil jwtUtil;

    public AdminController(
            UserRepository userRepository,
            RecipeRepository recipeRepository,
            JwtUtil jwtUtil
    ) {
        this.userRepository = userRepository;
        this.recipeRepository = recipeRepository;
        this.jwtUtil = jwtUtil;
    }

    // ===== ПРОВЕРКА АДМИНА =====
    private void checkAdmin(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Нет токена");
        }

        String token = authHeader.replace("Bearer ", "");
        String email = jwtUtil.extractEmail(token);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

        if (!"ADMIN".equals(user.getRole())) {
            throw new RuntimeException("Нет прав администратора");
        }
    }

    // ===== РЕЦЕПТЫ =====

    @PostMapping("/recipes")
    public Recipe addRecipe(
            @RequestHeader("Authorization") String auth,
            @RequestBody Recipe recipe
    ) {
        checkAdmin(auth);
        return recipeRepository.save(recipe);
    }

    @DeleteMapping("/recipes/{id}")
    public void deleteRecipe(
            @RequestHeader("Authorization") String auth,
            @PathVariable Long id
    ) {
        checkAdmin(auth);
        recipeRepository.deleteById(id);
    }

    // ===== ПОЛЬЗОВАТЕЛИ =====

    @GetMapping("/users")
    public List<User> getAllUsers(
            @RequestHeader("Authorization") String auth
    ) {
        checkAdmin(auth);
        return userRepository.findAll();
    }

    @DeleteMapping("/users/{id}")
    public void deleteUser(
            @RequestHeader("Authorization") String auth,
            @PathVariable Long id
    ) {
        checkAdmin(auth);
        userRepository.deleteById(id);
    }
}
