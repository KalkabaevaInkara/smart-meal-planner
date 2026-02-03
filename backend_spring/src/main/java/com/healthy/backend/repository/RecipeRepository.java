package com.healthy.backend.repository;

import com.healthy.backend.model.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RecipeRepository extends JpaRepository<Recipe, Long> {
    List<Recipe> findByDiet_Name(String name);
}
