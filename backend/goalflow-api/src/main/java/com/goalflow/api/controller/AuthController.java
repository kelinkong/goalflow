package com.goalflow.api.controller;

import com.goalflow.api.dto.LoginRequest;
import com.goalflow.api.dto.RegisterRequest;
import com.goalflow.api.dto.UpdateProfileRequest;
import com.goalflow.api.entity.User;
import com.goalflow.api.exception.BusinessException;
import com.goalflow.api.mapper.UserMapper;
import com.goalflow.api.security.JwtService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UserMapper userMapper;
    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        if (userService.findByEmail(request.getEmail()) != null) {
            throw new BusinessException("该邮箱已被注册", 400);
        }
        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .nickname(request.getNickname())
                .createdAt(LocalDateTime.now())
                .build();
        userMapper.insert(user);
        
        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String token = jwtService.generateToken(userDetails);
        String refreshToken = jwtService.generateRefreshToken(userDetails);
        return ResponseEntity.ok(Map.of("token", token, "refreshToken", refreshToken));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );
        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        String token = jwtService.generateToken(userDetails);
        String refreshToken = jwtService.generateRefreshToken(userDetails);
        return ResponseEntity.ok(Map.of("token", token, "refreshToken", refreshToken));
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody Map<String, String> body) {
        final String refreshToken = body.get("refreshToken");
        if (refreshToken == null || refreshToken.isEmpty()) {
            throw new BusinessException("refreshToken is required", 400);
        }
        try {
            final String username = jwtService.extractUsername(refreshToken);
            if (username == null || username.isEmpty()) {
                throw new BusinessException("Invalid refresh token", 401);
            }
            UserDetails userDetails = userDetailsService.loadUserByUsername(username);
            if (!jwtService.isRefreshTokenValid(refreshToken, userDetails)) {
                throw new BusinessException("Refresh token invalid or expired", 401);
            }
            String newToken = jwtService.generateToken(userDetails);
            String newRefresh = jwtService.generateRefreshToken(userDetails);
            return ResponseEntity.ok(Map.of("token", newToken, "refreshToken", newRefresh));
        } catch (Exception e) {
            throw new BusinessException("Refresh failed", 401);
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(@AuthenticationPrincipal UserDetails userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }
        User user = userService.requireByEmail(userDetails.getUsername());
        return ResponseEntity.ok(toProfileResponse(user));
    }

    @PutMapping("/me")
    public ResponseEntity<?> updateMe(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateProfileRequest request
    ) {
        if (userDetails == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }
        User user = userService.requireByEmail(userDetails.getUsername());
        User updatedUser = userService.updateProfile(user, request.getNickname(), request.getAvatar());
        return ResponseEntity.ok(toProfileResponse(updatedUser));
    }

    private Map<String, Object> toProfileResponse(User user) {
        Map<String, Object> data = new java.util.HashMap<>();
        data.put("id", user.getId());
        data.put("email", user.getEmail());
        data.put("nickname", user.getNickname());
        data.put("avatar", user.getAvatar());
        data.put("createdAt", user.getCreatedAt()); // 返回注册时间
        return data;
    }
}
