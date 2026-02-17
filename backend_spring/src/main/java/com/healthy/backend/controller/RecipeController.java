package com.healthy.backend.controller;

import com.healthy.backend.exception.NotFoundException;
import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.RecipeRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
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

    @GetMapping
    public List<Recipe> getAllRecipes() {
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

    @GetMapping("/by-diet")
    public List<Recipe> getByDiet(@RequestParam String diet) {
        List<Recipe> recipes = recipeRepository.findByDiet_Name(diet);

        if (recipes.isEmpty()) {
            throw new NotFoundException("No recipes for this diet");
        }

        return recipes;
    }
}
