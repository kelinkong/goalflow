package com.goalflow.api.controller;

import com.goalflow.api.dto.HabitCheckinCalendarDTO;
import com.goalflow.api.dto.HabitCheckinDTO;
import com.goalflow.api.dto.HabitCheckinUpsertRequest;
import com.goalflow.api.dto.HabitDTO;
import com.goalflow.api.dto.HabitUpsertRequest;
import com.goalflow.api.entity.User;
import com.goalflow.api.service.HabitService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/habits")
@RequiredArgsConstructor
public class HabitController {
    private final HabitService habitService;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<HabitDTO>> getHabits(@AuthenticationPrincipal UserDetails principal) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(habitService.getHabits(user));
    }

    @PostMapping
    public ResponseEntity<HabitDTO> createHabit(
            @AuthenticationPrincipal UserDetails principal,
            @RequestBody HabitUpsertRequest request
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(habitService.createHabit(user, request));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<HabitDTO> updateHabit(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id,
            @RequestBody HabitUpsertRequest request
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(habitService.updateHabit(user, id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteHabit(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        habitService.archiveHabit(user, id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/checkins/{date}")
    public ResponseEntity<HabitCheckinDTO> upsertCheckin(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id,
            @PathVariable String date,
            @RequestBody HabitCheckinUpsertRequest request
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(habitService.upsertCheckin(user, id, date, request));
    }

    @GetMapping("/checkins")
    public ResponseEntity<HabitCheckinCalendarDTO> getCheckins(
            @AuthenticationPrincipal UserDetails principal,
            @RequestParam String month
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(habitService.getCheckins(user, month));
    }
}
