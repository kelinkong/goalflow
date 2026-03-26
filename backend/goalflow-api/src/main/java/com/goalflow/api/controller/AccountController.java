package com.goalflow.api.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.goalflow.api.dto.GoalDTO;
import com.goalflow.api.entity.DayRecord;
import com.goalflow.api.entity.Medal;
import com.goalflow.api.entity.Ranking;
import com.goalflow.api.entity.TaskRecord;
import com.goalflow.api.entity.Template;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.DayRecordMapper;
import com.goalflow.api.mapper.MedalMapper;
import com.goalflow.api.mapper.RankingMapper;
import com.goalflow.api.mapper.TaskRecordMapper;
import com.goalflow.api.mapper.TemplateMapper;
import com.goalflow.api.service.GoalService;
import com.goalflow.api.service.TemplateService;
import com.goalflow.api.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/account")
@RequiredArgsConstructor
public class AccountController {
    private final UserService userService;
    private final GoalService goalService;
    private final TemplateService templateService;
    private final DayRecordMapper dayRecordMapper;
    private final TaskRecordMapper taskRecordMapper;
    private final MedalMapper medalMapper;
    private final RankingMapper rankingMapper;
    private final TemplateMapper templateMapper;

    @GetMapping("/export")
    public ResponseEntity<Map<String, Object>> exportData(@AuthenticationPrincipal UserDetails principal) {
        User user = userService.requireByEmail(principal.getUsername());
        List<GoalDTO> goals = goalService.getGoalsByUser(user);
        List<DayRecord> dayRecords = dayRecordMapper.selectList(
                new LambdaQueryWrapper<DayRecord>().eq(DayRecord::getUserId, user.getId())
        );
        List<Long> dayRecordIds = dayRecords.stream().map(DayRecord::getId).toList();
        List<TaskRecord> taskRecords = dayRecordIds.isEmpty()
                ? List.of()
                : taskRecordMapper.selectList(new QueryWrapper<TaskRecord>().in("day_record_id", dayRecordIds));
        List<Medal> medals = medalMapper.selectList(
                new LambdaQueryWrapper<Medal>().eq(Medal::getUserId, user.getId())
        );
        List<Ranking> rankings = rankingMapper.selectList(
                new LambdaQueryWrapper<Ranking>().eq(Ranking::getUserId, user.getId())
        );
        List<Template> templates = templateMapper.selectList(
                new LambdaQueryWrapper<Template>().eq(Template::getOwnerId, user.getId())
        );

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("exportedAt", LocalDateTime.now());
        payload.put("user", Map.of(
                "id", user.getId(),
                "email", user.getEmail(),
                "nickname", user.getNickname() == null ? "" : user.getNickname()
        ));
        payload.put("goals", goals);
        payload.put("dayRecords", dayRecords);
        payload.put("taskRecords", taskRecords);
        payload.put("medals", medals);
        payload.put("rankings", rankings);
        payload.put("templates", templateService.getMyTemplates(user));
        payload.put("rawTemplates", templates);
        return ResponseEntity.ok(payload);
    }

    @DeleteMapping("/history")
    public ResponseEntity<Void> clearHistory(@AuthenticationPrincipal UserDetails principal) {
        User user = userService.requireByEmail(principal.getUsername());
        goalService.clearHistory(user);
        return ResponseEntity.noContent().build();
    }
}
