package com.healthy.backend.repository;

import com.healthy.backend.model.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    // 🔍 Поиск по названию
    List<Recipe> findByTitleContainingIgnoreCase(String title);

    // 🥗 Фильтр по диете
    List<Recipe> findByDiet_NameIgnoreCase(String name);

    // 🔍 + 🥗 вместе
    List<Recipe> findByTitleContainingIgnoreCaseAndDiet_NameIgnoreCase(String title, String name);
}