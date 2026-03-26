package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.goalflow.api.dto.RankingEntryDTO;
import com.goalflow.api.entity.Goal;
import com.goalflow.api.entity.Ranking;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.RankingMapper;
import com.goalflow.api.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static org.springframework.http.HttpStatus.FORBIDDEN;

@Service
@RequiredArgsConstructor
public class RankingService {
    private final RankingMapper rankingMapper;
    private final UserMapper userMapper;

    public void syncGoalProgress(Goal goal, int progressPercent) {
        if (goal.getTemplateId() == null || !Boolean.TRUE.equals(goal.getJoinRanking())) {
            return;
        }
        Map<Long, Integer> oldRanks = loadCurrentRanks(goal.getTemplateId());
        Ranking ranking = rankingMapper.selectOne(
                new LambdaQueryWrapper<Ranking>()
                        .eq(Ranking::getTemplateId, goal.getTemplateId())
                        .eq(Ranking::getUserId, goal.getUserId())
        );
        if (ranking == null) {
            ranking = Ranking.builder()
                    .templateId(goal.getTemplateId())
                    .userId(goal.getUserId())
                    .build();
        }
        ranking.setProgressPercent(progressPercent);
        ranking.setUpdatedAt(LocalDateTime.now());
        upsertRanking(ranking);
        recomputeRanks(goal.getTemplateId(), oldRanks);
    }

    public List<RankingEntryDTO> getRankingByTemplate(Long templateId, Long viewerUserId) {
        Ranking viewer = rankingMapper.selectOne(
                new LambdaQueryWrapper<Ranking>()
                        .eq(Ranking::getTemplateId, templateId)
                        .eq(Ranking::getUserId, viewerUserId)
        );
        if (viewer == null) {
            throw new ResponseStatusException(FORBIDDEN, "仅加入该模板排行榜的用户可查看");
        }

        List<Ranking> rankings = rankingMapper.selectList(
                new LambdaQueryWrapper<Ranking>()
                        .eq(Ranking::getTemplateId, templateId)
                        .orderByDesc(Ranking::getProgressPercent)
                        .orderByAsc(Ranking::getUpdatedAt)
        );
        Map<Long, User> users = userMapper.selectBatchIds(
                rankings.stream().map(Ranking::getUserId).distinct().toList()
        ).stream().collect(Collectors.toMap(User::getId, user -> user));

        return rankings.stream().map(ranking -> {
            User user = users.get(ranking.getUserId());
            RankingEntryDTO dto = new RankingEntryDTO();
            dto.setUserId(ranking.getUserId());
            dto.setNickname(user == null
                    ? "用户" + ranking.getUserId()
                    : ((user.getNickname() != null && !user.getNickname().isBlank()) ? user.getNickname() : user.getEmail()));
            dto.setAvatar(user == null ? null : user.getAvatar());
            dto.setProgressPercent(ranking.getProgressPercent() == null ? 0 : ranking.getProgressPercent());
            int rank = rankOf(rankings, ranking.getUserId());
            dto.setRank(rank);
            int previousRank = ranking.getPreviousRank() == null || ranking.getPreviousRank() <= 0
                    ? rank
                    : ranking.getPreviousRank();
            dto.setRankChange(previousRank - rank);
            dto.setUpdatedAt(ranking.getUpdatedAt());
            return dto;
        }).toList();
    }

    private void upsertRanking(Ranking ranking) {
        if (ranking.getId() == null) {
            rankingMapper.insert(ranking);
        } else {
            rankingMapper.updateById(ranking);
        }
    }

    private Map<Long, Integer> loadCurrentRanks(Long templateId) {
        List<Ranking> previous = rankingMapper.selectList(
                new LambdaQueryWrapper<Ranking>()
                        .eq(Ranking::getTemplateId, templateId)
                        .orderByDesc(Ranking::getProgressPercent)
                        .orderByAsc(Ranking::getUpdatedAt)
        );
        Map<Long, Integer> oldRanks = new HashMap<>();
        for (int i = 0; i < previous.size(); i++) {
            oldRanks.put(previous.get(i).getUserId(), i + 1);
        }
        return oldRanks;
    }

    private void recomputeRanks(Long templateId, Map<Long, Integer> oldRanks) {
        List<Ranking> current = rankingMapper.selectList(
                new LambdaQueryWrapper<Ranking>()
                        .eq(Ranking::getTemplateId, templateId)
                        .orderByDesc(Ranking::getProgressPercent)
                        .orderByAsc(Ranking::getUpdatedAt)
        );
        for (Ranking ranking : current) {
            ranking.setPreviousRank(oldRanks.getOrDefault(ranking.getUserId(), 0));
            rankingMapper.updateById(ranking);
        }
    }

    private int rankOf(List<Ranking> rankings, Long userId) {
        for (int i = 0; i < rankings.size(); i++) {
            if (userId.equals(rankings.get(i).getUserId())) {
                return i + 1;
            }
        }
        return 0;
    }
}
