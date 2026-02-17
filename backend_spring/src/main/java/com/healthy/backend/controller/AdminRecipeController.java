package com.healthy.backend.controller;

import com.healthy.backend.exception.NotFoundException;
import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/admin/recipes")
@RequiredArgsConstructor
public class AdminRecipeController {

    private final RecipeRepository recipeRepository;

    @GetMapping
    public String listRecipes(Model model) {
        model.addAttribute("recipes", recipeRepository.findAll());
        model.addAttribute("recipe", new Recipe());
        return "admin";
    }

    @PostMapping("/add")
    public String addRecipe(@ModelAttribute Recipe recipe) {
        recipeRepository.save(recipe);
        return "redirect:/admin/recipes";
    }

    @GetMapping("/delete/{id}")
    public String deleteRecipe(@PathVariable Long id) {

        if (!recipeRepository.existsById(id)) {
            throw new NotFoundException("Recipe not found");
        }

        recipeRepository.deleteById(id);
        return "redirect:/admin/recipes";
    }
}
