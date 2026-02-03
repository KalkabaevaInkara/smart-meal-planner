package com.healthy.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "ingredients")
public class Ingredient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private Integer caloriesPer100g;
    private Float proteins;
    private Float fats;
    private Float carbs;

    // 🔹 ОБЯЗАТЕЛЬНО нужен пустой конструктор для JPA
    public Ingredient() {}

    // 🔹 Можно добавить конструктор для удобства (необязательно)
    public Ingredient(String name, Integer caloriesPer100g, Float proteins, Float fats, Float carbs) {
        this.name = name;
        this.caloriesPer100g = caloriesPer100g;
        this.proteins = proteins;
        this.fats = fats;
        this.carbs = carbs;
    }

    // 🔹 Геттеры и сеттеры (ОБЯЗАТЕЛЬНЫ для сериализации JSON)
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Integer getCaloriesPer100g() { return caloriesPer100g; }
    public void setCaloriesPer100g(Integer caloriesPer100g) { this.caloriesPer100g = caloriesPer100g; }

    public Float getProteins() { return proteins; }
    public void setProteins(Float proteins) { this.proteins = proteins; }

    public Float getFats() { return fats; }
    public void setFats(Float fats) { this.fats = fats; }

    public Float getCarbs() { return carbs; }
    public void setCarbs(Float carbs) { this.carbs = carbs; }
}
