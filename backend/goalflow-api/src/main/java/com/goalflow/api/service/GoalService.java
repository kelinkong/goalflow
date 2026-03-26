package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.goalflow.api.dto.GoalDTO;
import com.goalflow.api.entity.DayRecord;
import com.goalflow.api.entity.Goal;
import com.goalflow.api.entity.GoalPlanItem;
import com.goalflow.api.entity.Template;
import com.goalflow.api.entity.TemplatePlanItem;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.DayRecordMapper;
import com.goalflow.api.mapper.GoalMapper;
import com.goalflow.api.mapper.GoalPlanItemMapper;
import com.goalflow.api.mapper.MedalMapper;
import com.goalflow.api.mapper.RankingMapper;
import com.goalflow.api.mapper.TaskRecordMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

@Service
@RequiredArgsConstructor
public class GoalService {
    private final GoalMapper goalMapper;
    private final GoalPlanItemMapper goalPlanItemMapper;
    private final DayRecordMapper dayRecordMapper;
    private final TaskRecordMapper taskRecordMapper;
    private final MedalMapper medalMapper;
    private final RankingMapper rankingMapper;
    private final AIService aiService;
    private final RankingService rankingService;
    private final EntityValidationService validationService;

    public GoalDTO createGoal(User user, GoalDTO dto) {
        Goal goal = Goal.builder()
                .name(dto.getName())
                .emoji(dto.getEmoji())
                .description(dto.getDescription())
                .totalDays(dto.getTotalDays())
                .templateId(dto.getTemplateId())
                .userId(user.getId())
                .joinRanking(Boolean.TRUE.equals(dto.getJoinRanking()))
                .status(dto.getStatus() == null ? "ACTIVE" : dto.getStatus().toUpperCase())
                .createdAt(LocalDateTime.now())
                .build();
        goalMapper.insert(goal);

        List<List<String>> plan = dto.getTaskPlan();
        if (plan == null || plan.isEmpty()) {
            plan = aiService.decomposeGoal(goal.getName(), goal.getDescription(), goal.getTotalDays(), dto.getTaskCount());
        }

        List<GoalPlanItem> planItems = new ArrayList<>();
        for (int i = 0; i < plan.size(); i++) {
            List<String> tasks = plan.get(i);
            for (String task : tasks) {
                GoalPlanItem item = GoalPlanItem.builder()
                        .goalId(goal.getId())
                        .dayNumber(i)
                        .taskText(task)
                        .build();
                planItems.add(item);
            }
        }
        for (GoalPlanItem item : planItems) {
            goalPlanItemMapper.insert(item);
        }
        rankingService.syncGoalProgress(goal, 0);

        return toDTO(goal, planItems);
    }

    public GoalDTO createGoalFromTemplate(User user, Template template, boolean joinRanking) {
        cleanupDuplicateTemplateGoals(user.getId(), template.getId());
        Goal existing = findTemplateGoal(user.getId(), template.getId());
        if (existing != null) {
            throw new ResponseStatusException(BAD_REQUEST, "Template already used");
        }
        GoalDTO dto = GoalDTO.builder()
                .name(template.getName())
                .emoji("📘")
                .description(template.getDescription())
                .totalDays(template.getTotalDays())
                .templateId(template.getId())
                .joinRanking(joinRanking)
                .status("ACTIVE")
                .taskPlan(toTaskPlan(template))
                .build();
        return createGoal(user, dto);
    }

    public List<GoalDTO> getGoalsByUser(User user) {
        cleanupDuplicateTemplateGoals(user.getId(), null);
        List<Goal> goals = goalMapper.selectList(
                new LambdaQueryWrapper<Goal>().eq(Goal::getUserId, user.getId())
        );
        if (goals.isEmpty()) return Collections.emptyList();

        List<Long> goalIds = goals.stream().map(Goal::getId).toList();
        List<GoalPlanItem> planItems = goalPlanItemMapper.selectList(
                new LambdaQueryWrapper<GoalPlanItem>().in(GoalPlanItem::getGoalId, goalIds)
        );
        Map<Long, List<GoalPlanItem>> byGoal = planItems.stream()
                .collect(Collectors.groupingBy(GoalPlanItem::getGoalId));

        return goals.stream()
                .map(goal -> toDTO(goal, byGoal.getOrDefault(goal.getId(), List.of())))
                .toList();
    }

    /**
     * 根据 ID 获取目标（不验证所有权，用于公开场景）
     */
    public GoalDTO getGoalById(Long id) {
        Goal goal = goalMapper.selectById(id);
        if (goal == null) throw new RuntimeException("Goal not found");
        List<GoalPlanItem> planItems = goalPlanItemMapper.selectList(
                new LambdaQueryWrapper<GoalPlanItem>().eq(GoalPlanItem::getGoalId, id)
        );
        return toDTO(goal, planItems);
    }

    /**
     * 根据 ID 获取目标并验证所有权
     */
    public GoalDTO getGoalByIdWithOwnershipCheck(Long userId, Long id) {
        validationService.requireOwnedGoal(userId, id);
        return getGoalById(id);
    }

    public GoalDTO updateGoal(User user, Long goalId, GoalDTO dto) {
        Goal goal = validationService.requireOwnedGoal(user.getId(), goalId);
        if (dto.getName() != null && !dto.getName().isBlank()) {
            goal.setName(dto.getName().trim());
        }
        if (dto.getEmoji() != null && !dto.getEmoji().isBlank()) {
            goal.setEmoji(dto.getEmoji());
        }
        if (dto.getDescription() != null) {
            goal.setDescription(dto.getDescription());
        }
        if (dto.getTotalDays() != null && dto.getTotalDays() > 0) {
            goal.setTotalDays(dto.getTotalDays());
        }
        if (dto.getStatus() != null && !dto.getStatus().isBlank()) {
            goal.setStatus(dto.getStatus().toUpperCase());
        }
        goalMapper.updateById(goal);
        if (dto.getTaskPlan() != null && !dto.getTaskPlan().isEmpty()) {
            replacePlanItems(goalId, dto.getTaskPlan());
            if (dto.getTotalDays() == null) {
                goal.setTotalDays(dto.getTaskPlan().size());
                goalMapper.updateById(goal);
            }
        }
        return getGoalById(goalId);
    }

    public void deleteGoal(User user, Long goalId) {
        Goal goal = validationService.requireOwnedGoal(user.getId(), goalId);
        deleteGoalCascade(goal);
    }

    private GoalDTO toDTO(Goal goal, List<GoalPlanItem> planItems) {
        Map<Integer, List<String>> planMap = planItems.stream()
                .collect(Collectors.groupingBy(
                        GoalPlanItem::getDayNumber,
                        Collectors.mapping(GoalPlanItem::getTaskText, Collectors.toList())
                ));

        List<List<String>> taskPlan = new ArrayList<>();
        for (int i = 0; i < goal.getTotalDays(); i++) {
            taskPlan.add(planMap.getOrDefault(i, new ArrayList<>()));
        }

        return GoalDTO.builder()
                .id(goal.getId().toString())
                .name(goal.getName())
                .emoji(goal.getEmoji())
                .description(goal.getDescription())
                .totalDays(goal.getTotalDays())
                .templateId(goal.getTemplateId())
                .joinRanking(Boolean.TRUE.equals(goal.getJoinRanking()))
                .status(goal.getStatus() == null ? "ACTIVE" : goal.getStatus())
                .createdAt(goal.getCreatedAt())
                .taskPlan(taskPlan)
                .build();
    }

    private List<List<String>> toTaskPlan(Template template) {
        Map<Integer, List<String>> planMap = template.getPlanItems().stream()
                .collect(Collectors.groupingBy(
                        TemplatePlanItem::getDayNumber,
                        Collectors.mapping(TemplatePlanItem::getTaskText, Collectors.toList())
                ));
        List<List<String>> taskPlan = new ArrayList<>();
        for (int i = 0; i < template.getTotalDays(); i++) {
            taskPlan.add(planMap.getOrDefault(i, List.of()));
        }
        return taskPlan;
    }

    public void clearHistory(User user) {
        List<Goal> goals = goalMapper.selectList(
                new LambdaQueryWrapper<Goal>().eq(Goal::getUserId, user.getId())
        );
        for (Goal goal : goals) {
            deleteGoalCascade(goal);
        }
        rankingMapper.delete(new LambdaQueryWrapper<com.goalflow.api.entity.Ranking>()
                .eq(com.goalflow.api.entity.Ranking::getUserId, user.getId()));
        medalMapper.delete(new LambdaQueryWrapper<com.goalflow.api.entity.Medal>()
                .eq(com.goalflow.api.entity.Medal::getUserId, user.getId()));
    }

    private void replacePlanItems(Long goalId, List<List<String>> plan) {
        goalPlanItemMapper.delete(new LambdaQueryWrapper<GoalPlanItem>().eq(GoalPlanItem::getGoalId, goalId));
        for (int i = 0; i < plan.size(); i++) {
            for (String task : plan.get(i)) {
                goalPlanItemMapper.insert(GoalPlanItem.builder()
                        .goalId(goalId)
                        .dayNumber(i)
                        .taskText(task)
                        .build());
            }
        }
    }

    private Goal findTemplateGoal(Long userId, Long templateId) {
        return goalMapper.selectOne(new LambdaQueryWrapper<Goal>()
                .eq(Goal::getUserId, userId)
                .eq(Goal::getTemplateId, templateId)
                .last("limit 1"));
    }

    private void cleanupDuplicateTemplateGoals(Long userId, Long templateId) {
        LambdaQueryWrapper<Goal> query = new LambdaQueryWrapper<Goal>()
                .eq(Goal::getUserId, userId)
                .isNotNull(Goal::getTemplateId);
        if (templateId != null) {
            query.eq(Goal::getTemplateId, templateId);
        }
        List<Goal> templateGoals = goalMapper.selectList(query);
        Map<Long, List<Goal>> byTemplate = templateGoals.stream()
                .collect(Collectors.groupingBy(Goal::getTemplateId));
        for (List<Goal> sameTemplateGoals : byTemplate.values()) {
            if (sameTemplateGoals.size() <= 1) {
                continue;
            }
            sameTemplateGoals.sort(Comparator.comparing(Goal::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder())).reversed());
            for (int i = 1; i < sameTemplateGoals.size(); i++) {
                deleteGoalCascade(sameTemplateGoals.get(i));
            }
        }
    }

    private void deleteGoalCascade(Goal goal) {
        List<DayRecord> dayRecords = dayRecordMapper.selectList(
                new LambdaQueryWrapper<DayRecord>().eq(DayRecord::getGoalId, goal.getId())
        );
        List<Long> dayRecordIds = dayRecords.stream().map(DayRecord::getId).toList();
        if (!dayRecordIds.isEmpty()) {
            taskRecordMapper.delete(new QueryWrapper<com.goalflow.api.entity.TaskRecord>()
                    .in("day_record_id", dayRecordIds));
        }
        dayRecordMapper.delete(new LambdaQueryWrapper<DayRecord>().eq(DayRecord::getGoalId, goal.getId()));
        medalMapper.delete(new LambdaQueryWrapper<com.goalflow.api.entity.Medal>().eq(com.goalflow.api.entity.Medal::getGoalId, goal.getId()));
        goalPlanItemMapper.delete(new LambdaQueryWrapper<GoalPlanItem>().eq(GoalPlanItem::getGoalId, goal.getId()));
        goalMapper.deleteById(goal.getId());
        if (goal.getTemplateId() != null) {
            Long remaining = goalMapper.selectCount(new LambdaQueryWrapper<Goal>()
                    .eq(Goal::getUserId, goal.getUserId())
                    .eq(Goal::getTemplateId, goal.getTemplateId()));
            if (remaining == 0) {
                rankingMapper.delete(new LambdaQueryWrapper<com.goalflow.api.entity.Ranking>()
                        .eq(com.goalflow.api.entity.Ranking::getUserId, goal.getUserId())
                        .eq(com.goalflow.api.entity.Ranking::getTemplateId, goal.getTemplateId()));
            }
        }
    }
}
