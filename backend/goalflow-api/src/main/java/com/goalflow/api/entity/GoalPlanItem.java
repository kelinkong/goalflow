package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

@TableName("goal_plan_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GoalPlanItem {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long goalId;

    private Integer dayNumber;
    private String taskText;
}
