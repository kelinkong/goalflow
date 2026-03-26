package com.goalflow.api.controller;

import com.goalflow.api.dto.GoalDTO;
import com.goalflow.api.dto.RankingEntryDTO;
import com.goalflow.api.dto.TemplateCreateRequest;
import com.goalflow.api.dto.TemplateDTO;
import com.goalflow.api.dto.TemplateUseRequest;
import com.goalflow.api.entity.Template;
import com.goalflow.api.entity.User;
import com.goalflow.api.service.GoalService;
import com.goalflow.api.service.RankingService;
import com.goalflow.api.service.TemplateService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/templates")
@RequiredArgsConstructor
public class TemplateController {
    private final TemplateService templateService;
    private final GoalService goalService;
    private final RankingService rankingService;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<TemplateDTO>> getPublicTemplates() {
        return ResponseEntity.ok(templateService.getPublicTemplates());
    }

    @GetMapping("/my")
    public ResponseEntity<List<TemplateDTO>> getMyTemplates(@AuthenticationPrincipal UserDetails principal) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(templateService.getMyTemplates(user));
    }

    @PostMapping
    public ResponseEntity<TemplateDTO> createTemplate(
            @AuthenticationPrincipal UserDetails principal,
            @RequestBody TemplateCreateRequest request
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(templateService.createTemplate(user, request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TemplateDTO> getTemplate(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(templateService.getTemplateForUser(user, id));
    }

    @PostMapping("/{id}/publish")
    public ResponseEntity<TemplateDTO> publishTemplate(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        Template template = templateService.publishTemplate(user, id);
        return ResponseEntity.ok(templateService.getTemplateForUser(user, template.getId()));
    }

    @PostMapping("/{id}/use")
    public ResponseEntity<GoalDTO> useTemplate(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id,
            @RequestBody(required = false) TemplateUseRequest request
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        Template template = templateService.requireUsableTemplate(user, id);
        boolean joinRanking = request != null && Boolean.TRUE.equals(request.getJoinRanking());
        return ResponseEntity.ok(goalService.createGoalFromTemplate(user, template, joinRanking));
    }

    @GetMapping("/{id}/ranking")
    public ResponseEntity<List<RankingEntryDTO>> getRanking(
            @AuthenticationPrincipal UserDetails principal,
            @PathVariable Long id
    ) {
        User user = userService.requireByEmail(principal.getUsername());
        return ResponseEntity.ok(rankingService.getRankingByTemplate(id, user.getId()));
    }
}
