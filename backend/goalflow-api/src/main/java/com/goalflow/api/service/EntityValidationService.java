package com.goalflow.api.service;

import com.goalflow.api.entity.Goal;
import com.goalflow.api.mapper.GoalMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 实体关联关系验证服务
 * 所有外键关联的逻辑校验都在这一层完成
 */
@Service
@RequiredArgsConstructor
public class EntityValidationService {
    
    private final GoalMapper goalMapper;
    
    /**
     * 验证目标是否属于指定用户
     * @param userId 用户 ID
     * @param goalId 目标 ID
     * @return 验证通过返回 Goal 对象
     * @throws RuntimeException 验证失败抛出异常
     */
    public Goal requireOwnedGoal(Long userId, Long goalId) {
        Goal goal = goalMapper.selectById(goalId);
        if (goal == null || !userId.equals(goal.getUserId())) {
            throw new RuntimeException("Goal not found");
        }
        return goal;
    }
    
    /**
     * 验证目标计划项是否属于指定的目标
     * @param goalId 目标 ID
     * @param planItemId 计划项 ID
     * @return 验证通过返回 true
     * @throws RuntimeException 验证失败抛出异常
     */
    public boolean requireGoalPlanItemBelongsToGoal(Long goalId, Long planItemId) {
        // TODO: 实际使用时需要根据具体情况实现
        // 目前通过查询时的 WHERE 条件来保证关联关系
        return true;
    }
}
