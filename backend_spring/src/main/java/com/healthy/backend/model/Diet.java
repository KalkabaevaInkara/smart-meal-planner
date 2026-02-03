package com.healthy.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "diets")
public class Diet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String description;
}
