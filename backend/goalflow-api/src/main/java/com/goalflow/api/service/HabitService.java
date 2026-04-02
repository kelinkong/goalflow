package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.goalflow.api.dto.HabitCheckinCalendarDTO;
import com.goalflow.api.dto.HabitCheckinDTO;
import com.goalflow.api.dto.HabitCheckinUpsertRequest;
import com.goalflow.api.dto.HabitDTO;
import com.goalflow.api.dto.HabitUpsertRequest;
import com.goalflow.api.entity.Habit;
import com.goalflow.api.entity.HabitCheckin;
import com.goalflow.api.entity.User;
import com.goalflow.api.exception.BusinessException;
import com.goalflow.api.mapper.HabitCheckinMapper;
import com.goalflow.api.mapper.HabitMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HabitService {
    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");
    private static final Set<String> ALLOWED_STATUSES = Set.of("ACTIVE", "ARCHIVED");

    private final HabitMapper habitMapper;
    private final HabitCheckinMapper habitCheckinMapper;

    public List<HabitDTO> getHabits(User user) {
        List<Habit> habits = habitMapper.selectList(new LambdaQueryWrapper<Habit>()
                .eq(Habit::getUserId, user.getId())
                .eq(Habit::getStatus, "ACTIVE")
                .orderByDesc(Habit::getCreatedAt, Habit::getId));
        if (habits.isEmpty()) {
            return List.of();
        }

        List<Long> habitIds = habits.stream().map(Habit::getId).toList();
        List<HabitCheckin> checkins = habitCheckinMapper.selectList(new LambdaQueryWrapper<HabitCheckin>()
                .in(HabitCheckin::getHabitId, habitIds)
                .eq(HabitCheckin::getIsDone, true)
                .orderByDesc(HabitCheckin::getDate));
        Map<Long, List<HabitCheckin>> checkinsByHabit = checkins.stream()
                .collect(Collectors.groupingBy(HabitCheckin::getHabitId, LinkedHashMap::new, Collectors.toList()));

        LocalDate today = LocalDate.now();
        return habits.stream()
                .map(habit -> toDTO(habit, checkinsByHabit.getOrDefault(habit.getId(), List.of()), today))
                .toList();
    }

    public HabitDTO createHabit(User user, HabitUpsertRequest request) {
        validateCreateRequest(request);
        LocalDateTime now = LocalDateTime.now();
        Habit habit = Habit.builder()
                .userId(user.getId())
                .name(request.getName().trim())
                .category(normalizeCategory(request.getCategory()))
                .status("ACTIVE")
                .createdAt(now)
                .updatedAt(now)
                .build();
        habitMapper.insert(habit);
        return toDTO(habit, List.of(), LocalDate.now());
    }

    public HabitDTO updateHabit(User user, Long habitId, HabitUpsertRequest request) {
        Habit habit = requireOwnedHabit(user.getId(), habitId);
        if (request == null) {
            throw new BusinessException("习惯内容不能为空");
        }
        boolean changed = false;
        if (request.getName() != null) {
            String name = request.getName().trim();
            if (name.isEmpty()) {
                throw new BusinessException("习惯名称不能为空");
            }
            habit.setName(name);
            changed = true;
        }
        if (request.getCategory() != null) {
            habit.setCategory(normalizeCategory(request.getCategory()));
            changed = true;
        }
        if (request.getStatus() != null) {
            habit.setStatus(normalizeStatus(request.getStatus()));
            changed = true;
        }
        if (!changed) {
            return toDTO(habit, loadDoneCheckins(habitId), LocalDate.now());
        }
        habit.setUpdatedAt(LocalDateTime.now());
        habitMapper.updateById(habit);
        return toDTO(habit, loadDoneCheckins(habitId), LocalDate.now());
    }

    public void archiveHabit(User user, Long habitId) {
        Habit habit = requireOwnedHabit(user.getId(), habitId);
        if ("ARCHIVED".equals(habit.getStatus())) {
            return;
        }
        habitMapper.update(null, new LambdaUpdateWrapper<Habit>()
                .eq(Habit::getId, habitId)
                .set(Habit::getStatus, "ARCHIVED")
                .set(Habit::getUpdatedAt, LocalDateTime.now()));
    }

    @Transactional
    public HabitCheckinDTO upsertCheckin(User user, Long habitId, String dateText, HabitCheckinUpsertRequest request) {
        Habit habit = requireOwnedHabit(user.getId(), habitId);
        LocalDate date = parseDate(dateText);
        boolean isDone = normalizeIsDone(request);
        LocalDateTime now = LocalDateTime.now();

        if (!isDone) {
            habitCheckinMapper.delete(new LambdaQueryWrapper<HabitCheckin>()
                    .eq(HabitCheckin::getHabitId, habitId)
                    .eq(HabitCheckin::getDate, date));
        } else {
            habitCheckinMapper.upsert(HabitCheckin.builder()
                    .habitId(habitId)
                    .userId(user.getId())
                    .date(date)
                    .isDone(true)
                    .createdAt(now)
                    .updatedAt(now)
                    .build());
        }

        habitMapper.update(null, new LambdaUpdateWrapper<Habit>()
                .eq(Habit::getId, habitId)
                .set(Habit::getUpdatedAt, now));

        HabitCheckinDTO dto = new HabitCheckinDTO();
        dto.setHabitId(habit.getId());
        dto.setHabitName(habit.getName());
        dto.setCategory(habit.getCategory());
        dto.setDate(date.toString());
        dto.setIsDone(isDone);
        return dto;
    }

    public HabitCheckinCalendarDTO getCheckins(User user, String monthText) {
        YearMonth month = parseMonth(monthText);
        LocalDate start = month.atDay(1);
        LocalDate end = month.atEndOfMonth();

        List<HabitCheckin> checkins = habitCheckinMapper.selectList(new LambdaQueryWrapper<HabitCheckin>()
                .eq(HabitCheckin::getUserId, user.getId())
                .between(HabitCheckin::getDate, start, end)
                .eq(HabitCheckin::getIsDone, true)
                .orderByAsc(HabitCheckin::getDate, HabitCheckin::getHabitId));

        Map<Long, Habit> habitMap = loadHabitsForCheckins(checkins);
        HabitCheckinCalendarDTO dto = new HabitCheckinCalendarDTO();
        dto.setMonth(month.format(MONTH_FORMATTER));
        dto.setCheckins(checkins.stream()
                .map(checkin -> toCheckinDTO(checkin, habitMap.get(checkin.getHabitId())))
                .filter(item -> item.getHabitName() != null)
                .toList());
        return dto;
    }

    private HabitDTO toDTO(Habit habit, List<HabitCheckin> doneCheckins, LocalDate today) {
        HabitDTO dto = new HabitDTO();
        dto.setId(habit.getId());
        dto.setName(habit.getName());
        dto.setCategory(habit.getCategory());
        dto.setStatus(habit.getStatus());
        dto.setTodayDone(doneCheckins.stream().anyMatch(checkin -> today.equals(checkin.getDate())));
        dto.setStreak(calculateStreak(doneCheckins));
        dto.setCreatedAt(habit.getCreatedAt());
        dto.setUpdatedAt(habit.getUpdatedAt());
        return dto;
    }

    private HabitCheckinDTO toCheckinDTO(HabitCheckin checkin, Habit habit) {
        HabitCheckinDTO dto = new HabitCheckinDTO();
        dto.setHabitId(checkin.getHabitId());
        dto.setHabitName(habit == null ? null : habit.getName());
        dto.setCategory(habit == null ? null : habit.getCategory());
        dto.setDate(checkin.getDate().toString());
        dto.setIsDone(Boolean.TRUE.equals(checkin.getIsDone()));
        return dto;
    }

    private Map<Long, Habit> loadHabitsForCheckins(List<HabitCheckin> checkins) {
        if (checkins.isEmpty()) {
            return Map.of();
        }
        List<Long> habitIds = checkins.stream().map(HabitCheckin::getHabitId).distinct().toList();
        return habitMapper.selectList(new LambdaQueryWrapper<Habit>()
                        .in(Habit::getId, habitIds))
                .stream()
                .collect(Collectors.toMap(Habit::getId, habit -> habit));
    }

    private List<HabitCheckin> loadDoneCheckins(Long habitId) {
        return habitCheckinMapper.selectList(new LambdaQueryWrapper<HabitCheckin>()
                .eq(HabitCheckin::getHabitId, habitId)
                .eq(HabitCheckin::getIsDone, true)
                .orderByDesc(HabitCheckin::getDate));
    }

    private Habit requireOwnedHabit(Long userId, Long habitId) {
        Habit habit = habitMapper.selectById(habitId);
        if (habit == null || !userId.equals(habit.getUserId())) {
            throw new BusinessException("习惯不存在", 404);
        }
        return habit;
    }

    private void validateCreateRequest(HabitUpsertRequest request) {
        if (request == null) {
            throw new BusinessException("习惯内容不能为空");
        }
        if (request.getName() == null || request.getName().trim().isEmpty()) {
            throw new BusinessException("习惯名称不能为空");
        }
        if (request.getStatus() != null) {
            normalizeStatus(request.getStatus());
        }
    }

    private String normalizeCategory(String category) {
        if (category == null) {
            return null;
        }
        String trimmed = category.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String normalizeStatus(String status) {
        if (status == null || status.trim().isEmpty()) {
            throw new BusinessException("习惯状态不能为空");
        }
        String normalized = status.trim().toUpperCase();
        if (!ALLOWED_STATUSES.contains(normalized)) {
            throw new BusinessException("习惯状态不合法");
        }
        return normalized;
    }

    private boolean normalizeIsDone(HabitCheckinUpsertRequest request) {
        if (request == null || request.getIsDone() == null) {
            throw new BusinessException("是否完成不能为空");
        }
        return Boolean.TRUE.equals(request.getIsDone());
    }

    private LocalDate parseDate(String dateText) {
        try {
            return LocalDate.parse(dateText);
        } catch (DateTimeParseException e) {
            throw new BusinessException("日期格式不正确，应为 yyyy-MM-dd");
        }
    }

    private YearMonth parseMonth(String monthText) {
        try {
            return YearMonth.parse(monthText, MONTH_FORMATTER);
        } catch (DateTimeParseException e) {
            throw new BusinessException("月份格式不正确，应为 yyyy-MM");
        }
    }

    private int calculateStreak(List<HabitCheckin> doneCheckins) {
        if (doneCheckins.isEmpty()) {
            return 0;
        }
        List<LocalDate> dates = doneCheckins.stream()
                .map(HabitCheckin::getDate)
                .distinct()
                .sorted(Comparator.reverseOrder())
                .toList();

        LocalDate cursor = dates.get(0);
        int streak = 1;
        for (int i = 1; i < dates.size(); i++) {
            LocalDate next = dates.get(i);
            if (next.equals(cursor.minusDays(1))) {
                streak++;
                cursor = next;
                continue;
            }
            break;
        }
        return streak;
    }
}
