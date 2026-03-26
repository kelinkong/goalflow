package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.goalflow.api.dto.MedalDTO;
import com.goalflow.api.entity.Goal;
import com.goalflow.api.entity.Medal;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.GoalMapper;
import com.goalflow.api.mapper.MedalMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MedalService {
    private final MedalMapper medalMapper;
    private final GoalMapper goalMapper;

    public List<MedalDTO> getMyMedals(User user) {
        List<Medal> medals = medalMapper.selectList(
                new LambdaQueryWrapper<Medal>().eq(Medal::getUserId, user.getId())
        );
        if (medals.isEmpty()) {
            return Collections.emptyList();
        }
        Map<Long, Goal> goals = goalMapper.selectBatchIds(
                medals.stream().map(Medal::getGoalId).distinct().toList()
        ).stream().collect(Collectors.toMap(Goal::getId, goal -> goal));
        return medals.stream().map(medal -> {
            Goal goal = goals.get(medal.getGoalId());
            MedalDTO dto = new MedalDTO();
            dto.setId(medal.getId());
            dto.setGoalId(medal.getGoalId());
            dto.setGoalName(goal == null ? null : goal.getName());
            dto.setGoalEmoji(goal == null ? null : goal.getEmoji());
            dto.setTitle(medal.getTitle());
            dto.setAwardedAt(medal.getAwardedAt());
            return dto;
        }).toList();
    }

    public void awardGoalCompletionMedal(Goal goal) {
        Medal existing = medalMapper.selectOne(
                new LambdaQueryWrapper<Medal>()
                        .eq(Medal::getUserId, goal.getUserId())
                        .eq(Medal::getGoalId, goal.getId())
        );
        if (existing != null) {
            return;
        }
        Medal medal = Medal.builder()
                .userId(goal.getUserId())
                .goalId(goal.getId())
                .title(goal.getName() + " 完成勋章")
                .build();
        if (medal.getAwardedAt() == null) {
            medal.setAwardedAt(LocalDateTime.now());
        }
        medalMapper.insert(medal);
    }
}
