package com.healthy.backend.controller;

import com.healthy.backend.entity.User;
import com.healthy.backend.exception.BadRequestException;
import com.healthy.backend.exception.NotFoundException;
import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.UserRepository;
import com.healthy.backend.repository.RecipeRepository;
import com.healthy.backend.security.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Администратор API", description = "Управление пользователями и рецептами")
@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final UserRepository userRepository;
    private final RecipeRepository recipeRepository;
    private final JwtUtil jwtUtil;

    public AdminController(UserRepository userRepository,
                           RecipeRepository recipeRepository,
                           JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.recipeRepository = recipeRepository;
        this.jwtUtil = jwtUtil;
    }

    private void checkAdmin(String authHeader) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new BadRequestException("Отсутствует токен");
        }

        String token = authHeader.replace("Bearer ", "");
        String email = jwtUtil.extractEmail(token);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        if (!"ADMIN".equals(user.getRole())) {
            throw new BadRequestException("Нет прав администратора");
        }
    }

    @Operation(summary = "Добавить рецепт (только админ)")
    @ApiResponse(responseCode = "201", description = "Рецепт добавлен")
    @PostMapping("/recipes")
    public Recipe addRecipe(@RequestHeader("Authorization") String auth,
                            @RequestBody Recipe recipe) {
        checkAdmin(auth);
        return recipeRepository.save(recipe);
    }

    @Operation(summary = "Удалить рецепт (только админ)")
    @ApiResponse(responseCode = "204", description = "Удалён")
    @DeleteMapping("/recipes/{id}")
    public void deleteRecipe(@RequestHeader("Authorization") String auth,
                             @PathVariable Long id) {

        checkAdmin(auth);

        if (!recipeRepository.existsById(id)) {
            throw new NotFoundException("Recipe not found");
        }

        recipeRepository.deleteById(id);
    }

    @Operation(summary = "Получить список пользователей (админ)")
    @GetMapping("/users")
    public List<User> getAllUsers(@RequestHeader("Authorization") String auth) {
        checkAdmin(auth);
        return userRepository.findAll();
    }

    @Operation(summary = "Удалить пользователя (админ)")
    @DeleteMapping("/users/{id}")
    public void deleteUser(@RequestHeader("Authorization") String auth,
                           @PathVariable Long id) {

        checkAdmin(auth);

        if (!userRepository.existsById(id)) {
            throw new NotFoundException("User not found");
        }

        userRepository.deleteById(id);
    }
}
