package com.healthy.backend.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/admin")
public class AdminAuthController {

    @Value("${admin.email}")
    private String adminEmail;

    @Value("${admin.password}")
    private String adminPassword;

    @GetMapping("/login")
    public String loginPage() {
        return "admin-login";
    }

    @PostMapping("/login")
    public String doLogin(
            @RequestParam String email,
            @RequestParam String password,
            HttpSession session
    ) {
        if (email.equals(adminEmail) && password.equals(adminPassword)) {
            session.setAttribute("ADMIN", true);
            return "redirect:/admin";
        }
        return "redirect:/admin/login?error";
    }

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/admin/login";
    }
}
