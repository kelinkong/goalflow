package com.goalflow.api.config;

import com.goalflow.api.entity.User;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

@Configuration
@RequiredArgsConstructor
public class ApplicationConfig {
    private final UserService userService;

    @Value("${goalflow.admin.emails:admin@goalflow.com}")
    private String adminEmailsConfig;

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            User user = userService.findByEmail(username);
            if (user == null) throw new UsernameNotFoundException("User not found");
            Set<String> adminEmails = Arrays.stream(adminEmailsConfig.split(","))
                    .map(String::trim)
                    .filter(email -> !email.isEmpty())
                    .map(String::toLowerCase)
                    .collect(Collectors.toSet());
            ArrayList<SimpleGrantedAuthority> authorities = new ArrayList<>();
            if (adminEmails.contains(user.getEmail().trim().toLowerCase())) {
                authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
            }
            return new org.springframework.security.core.userdetails.User(
                    user.getEmail(),
                    user.getPassword(),
                    authorities
            );
        };
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService());
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
