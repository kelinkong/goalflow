package com.goalflow.api.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.goalflow.api.entity.*;
import com.goalflow.api.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserMapper userMapper;
    private final GoalMapper goalMapper;
    private final TaskRecordMapper taskRecordMapper;
    private final DayRecordMapper dayRecordMapper;
    private final TemplateMapper templateMapper;
    private final TemplatePlanItemMapper templatePlanItemMapper;
    private final RankingMapper rankingMapper;

    @org.springframework.beans.factory.annotation.Value("${logging.file.name:/tmp/goalflow.log}")
    private String logPath;

    /**
     * 获取仪表盘统计数据
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();

        // 总用户数
        Long totalUsers = Optional.ofNullable(
            userMapper.selectCount(null)
        ).orElse(0L);

        // 今日活跃用户（今日有打卡记录的用户）
        LocalDate today = LocalDate.now();
        QueryWrapper<DayRecord> todayQuery = new QueryWrapper<>();
        todayQuery.eq("DATE(date)", today);
        List<DayRecord> todayRecords = dayRecordMapper.selectList(todayQuery);
        Set<Long> activeUserIds = new HashSet<>();
        todayRecords.forEach(record -> activeUserIds.add(record.getUserId()));
        Long activeUsersToday = (long) activeUserIds.size();

        // 总目标数
        Long totalGoals = Optional.ofNullable(
            goalMapper.selectCount(null)
        ).orElse(0L);

        // 已完成目标
        QueryWrapper<Goal> completedGoalQuery = new QueryWrapper<>();
        completedGoalQuery.eq("status", "COMPLETED");
        Long completedGoals = Optional.ofNullable(
            goalMapper.selectCount(completedGoalQuery)
        ).orElse(0L);

        // 总任务数
        Long totalTasks = Optional.ofNullable(
            taskRecordMapper.selectCount(null)
        ).orElse(0L);

        // 已完成任务数
        QueryWrapper<TaskRecord> completedTaskQuery = new QueryWrapper<>();
        completedTaskQuery.eq("is_done", true);
        Long completedTasks = Optional.ofNullable(
            taskRecordMapper.selectCount(completedTaskQuery)
        ).orElse(0L);

        // 任务完成率
        Double taskCompletionRate = totalTasks > 0 ? 
            (completedTasks.doubleValue() / totalTasks * 100) : 0.0;

        // 模板总数
        Long templatesCount = Optional.ofNullable(
            templateMapper.selectCount(null)
        ).orElse(0L);

        // 待审核模板数
        QueryWrapper<Template> pendingTemplateQuery = new QueryWrapper<>();
        pendingTemplateQuery.eq("status", "PENDING");
        Long pendingTemplates = Optional.ofNullable(
            templateMapper.selectCount(pendingTemplateQuery)
        ).orElse(0L);

        stats.put("totalUsers", totalUsers);
        stats.put("activeUsersToday", activeUsersToday);
        stats.put("totalGoals", totalGoals);
        stats.put("completedGoals", completedGoals);
        stats.put("totalTasks", totalTasks);
        stats.put("completedTasks", completedTasks);
        stats.put("taskCompletionRate", Math.round(taskCompletionRate * 10.0) / 10.0);
        stats.put("templatesCount", templatesCount);
        stats.put("pendingTemplates", pendingTemplates);

        return ResponseEntity.ok(stats);
    }

    /**
     * 获取最近注册用户列表
     */
    @GetMapping("/users/recent")
    public ResponseEntity<List<Map<String, Object>>> getRecentUsers(
            @RequestParam(defaultValue = "20") int limit) {
        
        QueryWrapper<User> query = new QueryWrapper<>();
        query.orderByDesc("created_at");
        query.last("LIMIT " + limit);
        
        List<User> users = userMapper.selectList(query);
        List<Map<String, Object>> result = new ArrayList<>();
        
        for (User user : users) {
            Map<String, Object> userData = new HashMap<>();
            userData.put("id", user.getId());
            userData.put("email", user.getEmail());
            userData.put("nickname", user.getNickname());
            userData.put("avatar", user.getAvatar());
            userData.put("createdAt", user.getCreatedAt());
            result.add(userData);
        }
        
        return ResponseEntity.ok(result);
    }

    /**
     * 获取最近注册用户列表
     */
    @GetMapping("/users")
    public ResponseEntity<org.springframework.data.domain.Page<Map<String, Object>>> getUsers(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<User> userPage = 
            new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size);
        QueryWrapper<User> query = new QueryWrapper<>();
        query.orderByDesc("created_at");
        
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<User> resultPage = 
            userMapper.selectPage(userPage, query);
        
        java.util.List<Map<String, Object>> content = new java.util.ArrayList<>();
        for (User user : resultPage.getRecords()) {
            Map<String, Object> userData = new HashMap<>();
            userData.put("id", user.getId());
            userData.put("email", user.getEmail());
            userData.put("nickname", user.getNickname());
            userData.put("avatar", user.getAvatar());
            userData.put("createdAt", user.getCreatedAt());
            content.add(userData);
        }
        
        org.springframework.data.domain.Page<Map<String, Object>> springPage = 
            new org.springframework.data.domain.PageImpl<>(content, 
                org.springframework.data.domain.PageRequest.of(page - 1, size), 
                resultPage.getTotal());
        
        return ResponseEntity.ok(springPage);
    }

    /**
     * 获取热门目标（参与人数最多的目标）
     */
    @GetMapping("/goals/popular")
    public ResponseEntity<List<Map<String, Object>>> getPopularGoals(
            @RequestParam(defaultValue = "10") int limit) {
        
        // 查询所有目标
        List<Goal> goals = goalMapper.selectList(null);
        
        // 统计每个目标的参与人数和完成情况
        List<Map<String, Object>> result = new ArrayList<>();
        
        for (Goal goal : goals) {
            Map<String, Object> goalData = new HashMap<>();
            
            // 查询该目标的打卡记录数（代表参与天数）
            QueryWrapper<DayRecord> dayQuery = new QueryWrapper<>();
            dayQuery.eq("goal_id", goal.getId());
            Long dayCount = Optional.ofNullable(
                dayRecordMapper.selectCount(dayQuery)
            ).orElse(0L);
            
            // 查询该目标的任务完成情况
            QueryWrapper<TaskRecord> taskQuery = new QueryWrapper<>();
            taskQuery.in("day_record_id", 
                dayRecordMapper.selectObjs(new QueryWrapper<DayRecord>()
                    .select("id")
                    .eq("goal_id", goal.getId())
                )
            );
            
            Long totalTasks = Optional.ofNullable(
                taskRecordMapper.selectCount(taskQuery)
            ).orElse(0L);
            
            QueryWrapper<TaskRecord> completedTaskQuery = new QueryWrapper<>();
            completedTaskQuery.eq("is_done", true);
            Long completedTasks = Optional.ofNullable(
                taskRecordMapper.selectCount(completedTaskQuery)
            ).orElse(0L);
            
            // 计算完成率
            Double completionRate = totalTasks > 0 ? 
                (completedTasks.doubleValue() / totalTasks * 100) : 0.0;
            
            goalData.put("id", goal.getId());
            goalData.put("name", goal.getName());
            goalData.put("emoji", goal.getEmoji());
            goalData.put("userId", goal.getUserId());
            goalData.put("totalDays", goal.getTotalDays());
            goalData.put("status", goal.getStatus());
            goalData.put("userCount", dayCount); // 用打卡天数代表参与度
            goalData.put("completionRate", Math.round(completionRate * 10.0) / 10.0);
            
            result.add(goalData);
        }
        
        // 按参与人数排序
        result.sort((a, b) -> {
            Long countA = (Long) a.get("userCount");
            Long countB = (Long) b.get("userCount");
            return countB.compareTo(countA);
        });
        
        // 返回前 N 个
        return ResponseEntity.ok(
            result.subList(0, Math.min(limit, result.size()))
        );
    }

    /**
     * 获取所有目标列表
     */
    @GetMapping("/goals")
    public ResponseEntity<org.springframework.data.domain.Page<Map<String, Object>>> getGoals(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<Goal> goalPage = 
            new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size);
        QueryWrapper<Goal> query = new QueryWrapper<>();
        query.orderByDesc("created_at");
        
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<Goal> resultPage = 
            goalMapper.selectPage(goalPage, query);
        
        java.util.List<Map<String, Object>> content = new java.util.ArrayList<>();
        for (Goal goal : resultPage.getRecords()) {
            Map<String, Object> goalData = new HashMap<>();
            goalData.put("id", goal.getId());
            goalData.put("name", goal.getName());
            goalData.put("emoji", goal.getEmoji());
            goalData.put("description", goal.getDescription());
            goalData.put("totalDays", goal.getTotalDays());
            goalData.put("status", goal.getStatus());
            goalData.put("userId", goal.getUserId());
            goalData.put("createdAt", goal.getCreatedAt());
            content.add(goalData);
        }
        
        org.springframework.data.domain.Page<Map<String, Object>> springPage = 
            new org.springframework.data.domain.PageImpl<>(content, 
                org.springframework.data.domain.PageRequest.of(page - 1, size), 
                resultPage.getTotal());
        
        return ResponseEntity.ok(springPage);
    }

    /**
     * 获取系统日志（从文件读取）
     */
    @GetMapping("/logs")
    public ResponseEntity<Map<String, Object>> getSystemLogs(
            @RequestParam(defaultValue = "100") int lines) {
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            ProcessBuilder pb = new ProcessBuilder("tail", "-n", String.valueOf(lines), 
                logPath);
            Process process = pb.start();
            
            java.io.BufferedReader reader = new java.io.BufferedReader(
                new java.io.InputStreamReader(process.getInputStream())
            );
            
            StringBuilder logs = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                logs.append(line).append("\n");
            }
            
            result.put("success", true);
            result.put("logs", logs.toString());
        } catch (Exception e) {
            result.put("success", false);
            result.put("logs", "无法读取日志文件：" + e.getMessage());
        }
        
        return ResponseEntity.ok(result);
    }

    /**
     * 获取待审核模板列表
     */
    @GetMapping("/templates/pending")
    public ResponseEntity<List<Map<String, Object>>> getPendingTemplates() {
        QueryWrapper<Template> query = new QueryWrapper<>();
        query.eq("status", "PENDING").orderByDesc("created_at");
        
        List<Template> templates = templateMapper.selectList(query);
        return ResponseEntity.ok(templatesToMaps(templates));
    }

    /**
     * 获取已审核模板列表
     */
    @GetMapping("/templates/reviewed")
    public ResponseEntity<List<Map<String, Object>>> getReviewedTemplates(
            @RequestParam(required = false) String status) {
        
        QueryWrapper<Template> query = new QueryWrapper<>();
        if (status != null && !status.isEmpty()) {
            query.in("status", Arrays.asList("APPROVED", "REJECTED"));
            query.eq("status", status);
        } else {
            query.in("status", Arrays.asList("APPROVED", "REJECTED"));
        }
        query.orderByDesc("reviewed_at");
        
        List<Template> templates = templateMapper.selectList(query);
        return ResponseEntity.ok(templatesToMaps(templates));
    }

    /**
     * 审核通过模板
     */
    @PostMapping("/templates/{id}/approve")
    public ResponseEntity<Map<String, Object>> approveTemplate(@PathVariable Long id) {
        Template template = templateMapper.selectById(id);
        if (template == null) {
            return ResponseEntity.status(404).body(Map.of("error", "模板不存在"));
        }
        
        template.setStatus("APPROVED");
        template.setVisibility("PUBLIC");
        template.setReviewedAt(LocalDateTime.now());
        // 管理员 ID 暂时设为 1，后续可以从 token 中获取
        template.setReviewedBy(1L);
        templateMapper.updateById(template);
        
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * 拒绝模板
     */
    @PostMapping("/templates/{id}/reject")
    public ResponseEntity<Map<String, Object>> rejectTemplate(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        
        Template template = templateMapper.selectById(id);
        if (template == null) {
            return ResponseEntity.status(404).body(Map.of("error", "模板不存在"));
        }
        
        String reason = body.getOrDefault("reason", "未提供拒绝原因");
        template.setStatus("REJECTED");
        template.setVisibility("PRIVATE");
        template.setReviewedAt(LocalDateTime.now());
        template.setReviewedBy(1L);
        template.setRejectReason(reason);
        templateMapper.updateById(template);
        
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * 获取所有模板列表
     */
    @GetMapping("/templates")
    public ResponseEntity<List<Map<String, Object>>> getAllTemplates() {
        List<Template> templates = templateMapper.selectList(null);
        return ResponseEntity.ok(templatesToMaps(templates));
    }

    /**
     * 删除模板
     */
    @DeleteMapping("/templates/{id}")
    @Transactional
    public ResponseEntity<Map<String, Object>> deleteTemplate(@PathVariable Long id) {
        Template template = templateMapper.selectById(id);
        if (template == null) {
            return ResponseEntity.status(404).body(Map.of("error", "模板不存在"));
        }

        Long affectedGoals = goalMapper.selectCount(new QueryWrapper<Goal>().eq("template_id", id));

        goalMapper.update(
                null,
                new LambdaUpdateWrapper<Goal>()
                        .eq(Goal::getTemplateId, id)
                        .set(Goal::getTemplateId, null)
                        .set(Goal::getJoinRanking, false)
        );

        rankingMapper.delete(new QueryWrapper<Ranking>().eq("template_id", id));
        templatePlanItemMapper.delete(new QueryWrapper<TemplatePlanItem>().eq("template_id", id));
        templateMapper.deleteById(id);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("affectedGoals", affectedGoals);
        return ResponseEntity.ok(result);
    }

    private List<Map<String, Object>> templatesToMaps(List<Template> templates) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Template template : templates) {
            Map<String, Object> data = new HashMap<>();
            data.put("id", template.getId());
            data.put("ownerId", template.getOwnerId());
            data.put("name", template.getName());
            data.put("description", template.getDescription());
            data.put("totalDays", template.getTotalDays());
            data.put("visibility", template.getVisibility());
            data.put("tags", template.getTags());
            data.put("status", template.getStatus());
            data.put("reviewedAt", template.getReviewedAt());
            data.put("reviewedBy", template.getReviewedBy());
            data.put("rejectReason", template.getRejectReason());
            data.put("createdAt", template.getCreatedAt());
            result.add(data);
        }
        return result;
    }
}
