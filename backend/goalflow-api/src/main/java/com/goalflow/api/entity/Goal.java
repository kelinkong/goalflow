package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@TableName("goals")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Goal {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private String name;

    private String emoji;
    private String description;
    
    private Integer totalDays;
    private Long templateId;
    private Boolean joinRanking;

    private String status;

    private LocalDateTime createdAt;

    @TableField(exist = false)
    private List<GoalPlanItem> planItems;
}
