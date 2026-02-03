package com.healthy.backend.repository;

import com.healthy.backend.model.MealPlan;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MealPlanRepository extends JpaRepository<MealPlan, Long> {
}
