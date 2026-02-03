package com.healthy.backend.controller;

import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.RecipeRepository;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/recipes")
@CrossOrigin(origins = "*") // важно, чтобы React мог подключаться
public class RecipeController {

    private final RecipeRepository recipeRepository;

    public RecipeController(RecipeRepository recipeRepository) {
        this.recipeRepository = recipeRepository;
    }

    @GetMapping
    public List<Recipe> getAllRecipes() {
        return recipeRepository.findAll();
    }

    @GetMapping("/{id}")
    public Recipe getRecipeById(@PathVariable Long id) {
        return recipeRepository.findById(id).orElse(null);
    }

    @GetMapping("/by-diet")
    public List<Recipe> getByDiet(@RequestParam String diet) {
        return recipeRepository.findByDiet_Name(diet); // <-- важно, что здесь "Name", не "Type"
    }
}
