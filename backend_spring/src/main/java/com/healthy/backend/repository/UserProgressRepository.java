package com.healthy.backend.repository;

import com.healthy.backend.model.UserProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface UserProgressRepository extends JpaRepository<UserProgress, Long> {
    List<UserProgress> findByUserId(Long userId);
}
