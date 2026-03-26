package com.goalflow.api.controller;

import com.goalflow.api.dto.DailyReviewCalendarDTO;
import com.goalflow.api.dto.DailyReviewDTO;
import com.goalflow.api.dto.DailyReviewUpsertRequest;
import com.goalflow.api.entity.User;
import com.goalflow.api.service.DailyReviewService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/daily-reviews")
@RequiredArgsConstructor
public class DailyReviewController {
    private final DailyReviewService dailyReviewService;
    private final UserService userService;

    @GetMapping("/{date}")
    public ResponseEntity<DailyReviewDTO> getByDate(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable String date
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(dailyReviewService.getByDate(user, date));
    }

    @PutMapping("/{date}")
    public ResponseEntity<DailyReviewDTO> upsertByDate(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable String date,
            @RequestBody DailyReviewUpsertRequest request
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(dailyReviewService.upsertByDate(user, date, request));
    }

    @GetMapping("/calendar")
    public ResponseEntity<DailyReviewCalendarDTO> getCalendar(
            @AuthenticationPrincipal UserDetails principal,
            @RequestParam String month
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(dailyReviewService.getCalendar(user, month));
    }
}
