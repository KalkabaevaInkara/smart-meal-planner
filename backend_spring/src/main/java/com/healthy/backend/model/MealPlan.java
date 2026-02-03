package com.healthy.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.healthy.backend.entity.User;
import jakarta.persistence.*;
import java.sql.Date;

@Entity
@Table(name = "meal_plans")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class MealPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Date planDate;

    private Integer totalCalories;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    @JsonIgnoreProperties({"mealPlans", "password"}) // чтобы не зацикливалось в JSON
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "breakfast_id")
    private Recipe breakfast;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lunch_id")
    private Recipe lunch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "dinner_id")
    private Recipe dinner;

    // ---------- Конструкторы ----------
    public MealPlan() {}

    public MealPlan(Date planDate, Integer totalCalories, User user, Recipe breakfast, Recipe lunch, Recipe dinner) {
        this.planDate = planDate;
        this.totalCalories = totalCalories;
        this.user = user;
        this.breakfast = breakfast;
        this.lunch = lunch;
        this.dinner = dinner;
    }

    // ---------- Геттеры и сеттеры ----------
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Date getPlanDate() {
        return planDate;
    }

    public void setPlanDate(Date planDate) {
        this.planDate = planDate;
    }

    public Integer getTotalCalories() {
        return totalCalories;
    }

    public void setTotalCalories(Integer totalCalories) {
        this.totalCalories = totalCalories;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Recipe getBreakfast() {
        return breakfast;
    }

    public void setBreakfast(Recipe breakfast) {
        this.breakfast = breakfast;
    }

    public Recipe getLunch() {
        return lunch;
    }

    public void setLunch(Recipe lunch) {
        this.lunch = lunch;
    }

    public Recipe getDinner() {
        return dinner;
    }

    public void setDinner(Recipe dinner) {
        this.dinner = dinner;
    }
}
