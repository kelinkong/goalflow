package com.goalflow.api.controller;

import com.goalflow.api.dto.GoalDTO;
import com.goalflow.api.dto.GoalDecompositionDTO;
import com.goalflow.api.dto.TaskActionRequest;
import com.goalflow.api.dto.TimelineDayDTO;
import com.goalflow.api.entity.User;
import com.goalflow.api.service.AIService;
import com.goalflow.api.service.GoalService;
import com.goalflow.api.service.GoalTrackingService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/goals")
@RequiredArgsConstructor
public class GoalController {
    private final GoalService goalService;
    private final AIService aiService;
    private final GoalTrackingService goalTrackingService;
    private final UserService userService;

    @PostMapping
    public ResponseEntity<GoalDTO> createGoal(@AuthenticationPrincipal UserDetails principal, @RequestBody GoalDTO goalDTO) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(goalService.createGoal(user, goalDTO));
    }

    @GetMapping
    public ResponseEntity<List<GoalDTO>> getGoals(@AuthenticationPrincipal UserDetails principal) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(goalService.getGoalsByUser(user));
    }

    @GetMapping("/{id}")
    public ResponseEntity<GoalDTO> getGoal(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(goalService.getGoalByIdWithOwnershipCheck(user.getId(), id));
    }

    @PostMapping("/decompose")
    public ResponseEntity<GoalDecompositionDTO> decompose(@RequestBody GoalDTO goalDTO) {
        return ResponseEntity.ok(aiService.decomposeGoalDetailed(
                goalDTO.getName(),
                goalDTO.getDescription(),
                goalDTO.getTotalDays(),
                goalDTO.getTaskCount()
        ));
    }

    @GetMapping("/{id}/timeline")
    public ResponseEntity<List<TimelineDayDTO>> timeline(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(goalTrackingService.getTimeline(user, id));
    }

    @PostMapping("/{id}/checkin")
    public ResponseEntity<?> checkIn(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id,
            @RequestBody TaskActionRequest req
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        goalTrackingService.checkIn(user, id, req);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/defer")
    public ResponseEntity<?> defer(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id,
            @RequestBody TaskActionRequest req
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        goalTrackingService.defer(user, id, req);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}")
    public ResponseEntity<GoalDTO> updateGoal(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id,
            @RequestBody GoalDTO goalDTO
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(goalService.updateGoal(user, id, goalDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteGoal(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        goalService.deleteGoal(user, id);
        return ResponseEntity.noContent().build();
    }
}
