package com.goalflow.api.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.goalflow.api.entity.*;
import com.goalflow.api.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserMapper userMapper;
    private final GoalMapper goalMapper;
    private final DailyReviewMapper dailyReviewMapper;

    /**
     * 获取仪表盘统计数据 (三层模型健康度)
     */
    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();

        // 1. 总用户数
        stats.put("totalUsers", Optional.ofNullable(userMapper.selectCount(null)).orElse(0L));

        // 2. 活跃目标数 (目标支柱)
        QueryWrapper<Goal> activeGoalQuery = new QueryWrapper<>();
        activeGoalQuery.eq("status", "ACTIVE");
        stats.put("totalGoals", Optional.ofNullable(goalMapper.selectCount(activeGoalQuery)).orElse(0L));

        // 3. 正在坚持的习惯 (习惯支柱 - 首版占位)
        stats.put("totalHabits", 0);

        // 4. 累计复盘次数 (复盘支柱)
        stats.put("totalReviews", Optional.ofNullable(dailyReviewMapper.selectCount(null)).orElse(0L));

        return ResponseEntity.ok(stats);
    }

    /**
     * 获取用户列表 (分页)
     */
    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getUsers(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<User> userPage = 
            new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size);
        
        userMapper.selectPage(userPage, new QueryWrapper<User>().orderByDesc("created_at"));
        
        Map<String, Object> result = new HashMap<>();
        result.put("content", userPage.getRecords());
        result.put("totalElements", userPage.getTotal());
        result.put("totalPages", userPage.getPages());
        
        return ResponseEntity.ok(result);
    }

    /**
     * 获取所有目标列表 (分页)
     */
    @GetMapping("/goals")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getGoals(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<Goal> goalPage = 
            new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size);
        
        goalMapper.selectPage(goalPage, new QueryWrapper<Goal>().orderByDesc("created_at"));
        
        Map<String, Object> result = new HashMap<>();
        result.put("content", goalPage.getRecords());
        result.put("totalElements", goalPage.getTotal());
        result.put("totalPages", goalPage.getPages());
        
        return ResponseEntity.ok(result);
    }
}
