package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.goalflow.api.dto.TaskActionRequest;
import com.goalflow.api.dto.TimelineDayDTO;
import com.goalflow.api.dto.TimelineTaskDTO;
import com.goalflow.api.entity.DayRecord;
import com.goalflow.api.entity.Goal;
import com.goalflow.api.entity.GoalPlanItem;
import com.goalflow.api.entity.TaskRecord;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.DayRecordMapper;
import com.goalflow.api.mapper.GoalMapper;
import com.goalflow.api.mapper.GoalPlanItemMapper;
import com.goalflow.api.mapper.TaskRecordMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GoalTrackingService {
    private final GoalMapper goalMapper;
    private final GoalPlanItemMapper goalPlanItemMapper;
    private final DayRecordMapper dayRecordMapper;
    private final TaskRecordMapper taskRecordMapper;
    private final EntityValidationService validationService;
    private final RankingService rankingService;
    private final MedalService medalService;

    public List<TimelineDayDTO> getTimeline(User user, Long goalId) {
        Goal goal = validationService.requireOwnedGoal(user.getId(), goalId);
        Map<Integer, List<String>> planMap = getPlanMap(goalId);
        Map<Long, DayRecord> dayById = getDayRecordMap(user.getId(), goalId);
        Map<String, TaskRecord> taskRecordByKey = getTaskRecordMap(dayById);
        Map<String, List<TaskRecord>> deferredToMap = deferredToMap(dayById, taskRecordByKey);

        List<TimelineDayDTO> result = new ArrayList<>();
        LocalDate start = goal.getCreatedAt().toLocalDate();
        for (int i = 0; i < goal.getTotalDays(); i++) {
            LocalDate date = start.plusDays(i);
            String dateKey = date.toString();
            TimelineDayDTO day = new TimelineDayDTO();
            day.setDate(dateKey);
            day.setDayNumber(i + 1);

            List<TimelineTaskDTO> tasks = new ArrayList<>();
            List<String> baseTasks = planMap.getOrDefault(i, List.of());
            for (int idx = 0; idx < baseTasks.size(); idx++) {
                String key = recordKey(date, idx);
                TaskRecord rec = taskRecordByKey.get(key);
                TimelineTaskDTO task = new TimelineTaskDTO();
                task.setTaskIndex(idx);
                task.setSourceDate(dateKey);
                task.setText(baseTasks.get(idx));
                task.setDone(rec != null && rec.isDone());
                task.setDeferred(rec != null && rec.isDeferred());
                task.setMakeup(rec != null && rec.isMakeup());
                tasks.add(task);
            }

            for (TaskRecord rec : deferredToMap.getOrDefault(dateKey, List.of())) {
                DayRecord sourceDay = dayById.get(rec.getDayRecordId());
                if (sourceDay == null) continue;
                LocalDate sourceDate = sourceDay.getDate();
                if (sourceDate.equals(date)) continue;
                TimelineTaskDTO task = new TimelineTaskDTO();
                task.setTaskIndex(rec.getTaskIndex());
                task.setSourceDate(sourceDate.toString());
                task.setText(rec.getTaskText());
                task.setDone(rec.isDone());
                task.setDeferred(true);
                task.setMakeup(rec.isMakeup());
                tasks.add(task);
            }

            tasks.sort(Comparator.comparing(TimelineTaskDTO::getTaskIndex));
            day.setTasks(tasks);
            result.add(day);
        }

        return result;
    }

    public void checkIn(User user, Long goalId, TaskActionRequest req) {
        Goal goal = validationService.requireOwnedGoal(user.getId(), goalId);
        LocalDate sourceDate = parseDate(req.getSourceDate(), "sourceDate");
        Integer taskIndex = requireTaskIndex(req.getTaskIndex());
        TaskRecord record = getOrCreateTaskRecord(user, goal, sourceDate, taskIndex);
        
        boolean newDoneStatus = req.getDone() == null ? true : req.getDone();
        record.setDone(newDoneStatus);
        record.setDeferred(false);
        record.setDeferredTo(null);
        record.setMakeup(Boolean.TRUE.equals(req.getIsMakeup()));
        record.setDoneAt(newDoneStatus ? LocalDateTime.now() : null);
        upsertTaskRecord(record);
        syncGoalDerivedState(goal);
    }

    public void defer(User user, Long goalId, TaskActionRequest req) {
        Goal goal = validationService.requireOwnedGoal(user.getId(), goalId);
        LocalDate sourceDate = parseDate(req.getSourceDate(), "sourceDate");
        Integer taskIndex = requireTaskIndex(req.getTaskIndex());
        LocalDate targetDate = req.getTargetDate() == null || req.getTargetDate().isBlank()
                ? sourceDate.plusDays(1)
                : parseDate(req.getTargetDate(), "targetDate");

        TaskRecord record = getOrCreateTaskRecord(user, goal, sourceDate, taskIndex);
        record.setDone(false);
        record.setDeferred(true);
        record.setDeferredTo(targetDate.toString());
        record.setDoneAt(null);
        upsertTaskRecord(record);
        syncGoalDerivedState(goal);
    }

    private Integer requireTaskIndex(Integer taskIndex) {
        if (taskIndex == null || taskIndex < 0) {
            throw new RuntimeException("Invalid taskIndex");
        }
        return taskIndex;
    }

    private LocalDate parseDate(String date, String field) {
        if (date == null || date.isBlank()) {
            throw new RuntimeException("Missing " + field);
        }
        return LocalDate.parse(date);
    }

    private Map<Integer, List<String>> getPlanMap(Long goalId) {
        List<GoalPlanItem> planItems = goalPlanItemMapper.selectList(
                new LambdaQueryWrapper<GoalPlanItem>().eq(GoalPlanItem::getGoalId, goalId)
        );
        return planItems.stream()
                .collect(Collectors.groupingBy(
                        GoalPlanItem::getDayNumber,
                        Collectors.mapping(GoalPlanItem::getTaskText, Collectors.toList())
                ));
    }

    private Map<Long, DayRecord> getDayRecordMap(Long userId, Long goalId) {
        List<DayRecord> dayRecords = dayRecordMapper.selectList(
                new LambdaQueryWrapper<DayRecord>()
                        .eq(DayRecord::getUserId, userId)
                        .eq(DayRecord::getGoalId, goalId)
        );
        return dayRecords.stream().collect(Collectors.toMap(DayRecord::getId, d -> d));
    }

    private Map<String, TaskRecord> getTaskRecordMap(Map<Long, DayRecord> dayById) {
        if (dayById.isEmpty()) return new HashMap<>();
        List<Long> dayIds = new ArrayList<>(dayById.keySet());
        List<TaskRecord> records = taskRecordMapper.selectList(
                new LambdaQueryWrapper<TaskRecord>().in(TaskRecord::getDayRecordId, dayIds)
        );
        Map<String, TaskRecord> map = new HashMap<>();
        for (TaskRecord r : records) {
            DayRecord d = dayById.get(r.getDayRecordId());
            if (d == null || r.getTaskIndex() == null) continue;
            map.put(recordKey(d.getDate(), r.getTaskIndex()), r);
        }
        return map;
    }

    private Map<String, List<TaskRecord>> deferredToMap(
            Map<Long, DayRecord> dayById,
            Map<String, TaskRecord> taskRecordByKey
    ) {
        Map<String, List<TaskRecord>> map = new HashMap<>();
        for (TaskRecord r : taskRecordByKey.values()) {
            if (!r.isDeferred() || r.getDeferredTo() == null || r.getDeferredTo().isBlank()) continue;
            map.computeIfAbsent(r.getDeferredTo(), k -> new ArrayList<>()).add(r);
        }
        return map;
    }

    private TaskRecord getOrCreateTaskRecord(User user, Goal goal, LocalDate sourceDate, Integer taskIndex) {
        Integer dayNumber = (int) ChronoUnit.DAYS.between(goal.getCreatedAt().toLocalDate(), sourceDate);
        if (dayNumber < 0 || dayNumber >= goal.getTotalDays()) {
            throw new RuntimeException("sourceDate out of goal range");
        }

        List<String> tasks = getPlanMap(goal.getId()).getOrDefault(dayNumber, List.of());
        if (taskIndex >= tasks.size()) {
            throw new RuntimeException("taskIndex out of range");
        }
        String taskText = tasks.get(taskIndex);

        DayRecord dayRecord = dayRecordMapper.selectOne(
                new LambdaQueryWrapper<DayRecord>()
                        .eq(DayRecord::getUserId, user.getId())
                        .eq(DayRecord::getGoalId, goal.getId())
                        .eq(DayRecord::getDate, sourceDate)
        );
        if (dayRecord == null) {
            dayRecord = DayRecord.builder()
                    .userId(user.getId())
                    .goalId(goal.getId())
                    .date(sourceDate)
                    .dayNumber(dayNumber)
                    .build();
            dayRecordMapper.insert(dayRecord);
        }

        TaskRecord record = taskRecordMapper.selectOne(
                new LambdaQueryWrapper<TaskRecord>()
                        .eq(TaskRecord::getDayRecordId, dayRecord.getId())
                        .eq(TaskRecord::getTaskIndex, taskIndex)
        );
        if (record == null) {
            record = TaskRecord.builder()
                    .dayRecordId(dayRecord.getId())
                    .taskIndex(taskIndex)
                    .taskText(taskText)
                    .isDone(false)
                    .isDeferred(false)
                    .isMakeup(false)
                    .build();
        } else {
            record.setTaskText(taskText);
        }
        return record;
    }

    private void upsertTaskRecord(TaskRecord record) {
        if (record.getId() == null) {
            taskRecordMapper.insert(record);
        } else {
            taskRecordMapper.updateById(record);
        }
    }

    private void syncGoalDerivedState(Goal goal) {
        int totalTasks = goalPlanItemMapper.selectCount(
                new LambdaQueryWrapper<GoalPlanItem>().eq(GoalPlanItem::getGoalId, goal.getId())
        ).intValue();
        int doneTasks = taskRecordMapper.selectCount(
                new QueryWrapper<TaskRecord>()
                        .inSql("day_record_id", "select id from day_records where goal_id = " + goal.getId())
                        .eq("is_done", true)
        ).intValue();
        int progressPercent = totalTasks == 0 ? 0 : (int) Math.round((doneTasks * 100.0) / totalTasks);
        rankingService.syncGoalProgress(goal, progressPercent);
        if (progressPercent >= 100 && !"COMPLETED".equalsIgnoreCase(goal.getStatus())) {
            goal.setStatus("COMPLETED");
            goalMapper.updateById(goal);
            medalService.awardGoalCompletionMedal(goal);
        }
    }

    private String recordKey(LocalDate date, Integer taskIndex) {
        return date + "|" + taskIndex;
    }
}
