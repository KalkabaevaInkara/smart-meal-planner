package com.healthy.backend.repository;

import com.healthy.backend.model.Diet;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DietRepository extends JpaRepository<Diet, Long> {
}
