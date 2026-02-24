package com.healthy.backend.controller;

import com.healthy.backend.exception.NotFoundException;
import com.healthy.backend.model.Recipe;
import com.healthy.backend.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
@RequestMapping("/admin/recipes")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminRecipeController {

    private final RecipeRepository recipeRepository;

    @GetMapping
    public String listRecipes(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String diet,
            Model model) {

        List<Recipe> recipes;

        if (search != null && !search.isBlank() &&
                diet != null && !diet.isBlank()) {

            recipes = recipeRepository
                    .findByTitleContainingIgnoreCaseAndDiet_NameIgnoreCase(search, diet);

        } else if (search != null && !search.isBlank()) {

            recipes = recipeRepository
                    .findByTitleContainingIgnoreCase(search);

        } else if (diet != null && !diet.isBlank()) {

            recipes = recipeRepository
                    .findByDiet_NameIgnoreCase(diet);

        } else {
            recipes = recipeRepository.findAll();
        }

        model.addAttribute("recipes", recipes);
        model.addAttribute("recipe", new Recipe());
        model.addAttribute("search", search);
        model.addAttribute("diet", diet);

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