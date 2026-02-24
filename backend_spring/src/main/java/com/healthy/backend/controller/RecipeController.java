package com.healthy.backend.controller;

import com.healthy.backend.exception.NotFoundException;
import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.RecipeRepository;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Рецепты", description = "Получение и управление рецептами")
@RestController
@RequestMapping("/api/recipes")
@CrossOrigin(origins = "*")
public class RecipeController {

    private final RecipeRepository recipeRepository;

    public RecipeController(RecipeRepository recipeRepository) {
        this.recipeRepository = recipeRepository;
    }

    // 🔍 Поиск + фильтрация
    @GetMapping
    public List<Recipe> getRecipes(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String diet) {

        if (search != null && !search.isBlank() &&
                diet != null && !diet.isBlank()) {

            return recipeRepository
                    .findByTitleContainingIgnoreCaseAndDiet_NameIgnoreCase(search, diet);
        }

        if (search != null && !search.isBlank()) {
            return recipeRepository
                    .findByTitleContainingIgnoreCase(search);
        }

        if (diet != null && !diet.isBlank()) {
            return recipeRepository
                    .findByDiet_NameIgnoreCase(diet);
        }

        return recipeRepository.findAll();
    }

    @PostMapping
    public ResponseEntity<Recipe> createRecipe(@RequestBody Recipe recipe) {
        Recipe saved = recipeRepository.save(recipe);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRecipe(@PathVariable Long id) {

        if (!recipeRepository.existsById(id)) {
            throw new NotFoundException("Recipe not found");
        }

        recipeRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}")
    public Recipe getRecipeById(@PathVariable Long id) {
        return recipeRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Recipe not found"));
    }
}