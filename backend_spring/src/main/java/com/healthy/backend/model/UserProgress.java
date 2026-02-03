package com.healthy.backend.model;

import jakarta.persistence.*;
import java.sql.Date;
import com.healthy.backend.entity.User;


@Entity
@Table(name = "user_progress")
public class UserProgress {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Date date;
    private Float weight;
    private Integer caloriesConsumed;
    private Integer caloriesBurned;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}
