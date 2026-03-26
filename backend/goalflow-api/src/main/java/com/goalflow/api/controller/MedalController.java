package com.goalflow.api.controller;

import com.goalflow.api.dto.MedalDTO;
import com.goalflow.api.entity.User;
import com.goalflow.api.service.MedalService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/medals")
@RequiredArgsConstructor
public class MedalController {
    private final MedalService medalService;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<MedalDTO>> getMyMedals(@AuthenticationPrincipal UserDetails principal) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(medalService.getMyMedals(user));
    }
}
