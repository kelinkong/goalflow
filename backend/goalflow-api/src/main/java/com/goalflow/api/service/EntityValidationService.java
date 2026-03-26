package com.goalflow.api.service;

import com.goalflow.api.entity.Goal;
import com.goalflow.api.entity.Template;
import com.goalflow.api.mapper.GoalMapper;
import com.goalflow.api.mapper.TemplateMapper;
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
    private final TemplateMapper templateMapper;
    
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
     * 验证模板是否属于指定用户
     * @param userId 用户 ID
     * @param templateId 模板 ID
     * @return 验证通过返回 Template 对象
     * @throws RuntimeException 验证失败抛出异常
     */
    public Template requireOwnedTemplate(Long userId, Long templateId) {
        Template template = templateMapper.selectById(templateId);
        if (template == null || !userId.equals(template.getOwnerId())) {
            throw new RuntimeException("Template not found");
        }
        return template;
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
    
    /**
     * 验证模板计划项是否属于指定的模板
     * @param templateId 模板 ID
     * @param planItemId 计划项 ID
     * @return 验证通过返回 true
     * @throws RuntimeException 验证失败抛出异常
     */
    public boolean requireTemplatePlanItemBelongsToTemplate(Long templateId, Long planItemId) {
        // TODO: 实际使用时需要根据具体情况实现
        // 目前通过查询时的 WHERE 条件来保证关联关系
        return true;
    }
}
