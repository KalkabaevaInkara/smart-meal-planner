package com.healthy.backend.model;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "recipes")
public class Recipe {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;
    private Integer calories;
    private Float proteins;
    private Float fats;
    private Float carbs;
    private String imageUrl;
    private Integer cookingTime;
    private String difficulty;

    @ManyToOne
    @JoinColumn(name = "diet_id")
    private Diet diet;

    // 🔹 Добавляем связь с ингредиентами
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "recipe_ingredients",
            joinColumns = @JoinColumn(name = "recipe_id"),
            inverseJoinColumns = @JoinColumn(name = "ingredient_id")
    )
    private List<Ingredient> ingredients;

    // --- Конструкторы ---
    public Recipe() {}

    public Recipe(String title, String description, Integer calories, Float proteins,
                  Float fats, Float carbs, String imageUrl, Integer cookingTime, String difficulty) {
        this.title = title;
        this.description = description;
        this.calories = calories;
        this.proteins = proteins;
        this.fats = fats;
        this.carbs = carbs;
        this.imageUrl = imageUrl;
        this.cookingTime = cookingTime;
        this.difficulty = difficulty;
    }

    // --- Геттеры и сеттеры ---
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getCalories() {
        return calories;
    }

    public void setCalories(Integer calories) {
        this.calories = calories;
    }

    public Float getProteins() {
        return proteins;
    }

    public void setProteins(Float proteins) {
        this.proteins = proteins;
    }

    public Float getFats() {
        return fats;
    }

    public void setFats(Float fats) {
        this.fats = fats;
    }

    public Float getCarbs() {
        return carbs;
    }

    public void setCarbs(Float carbs) {
        this.carbs = carbs;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Integer getCookingTime() {
        return cookingTime;
    }

    public void setCookingTime(Integer cookingTime) {
        this.cookingTime = cookingTime;
    }

    public String getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(String difficulty) {
        this.difficulty = difficulty;
    }

    public Diet getDiet() {
        return diet;
    }

    public void setDiet(Diet diet) {
        this.diet = diet;
    }

    public List<Ingredient> getIngredients() {
        return ingredients;
    }

    public void setIngredients(List<Ingredient> ingredients) {
        this.ingredients = ingredients;
    }
}
