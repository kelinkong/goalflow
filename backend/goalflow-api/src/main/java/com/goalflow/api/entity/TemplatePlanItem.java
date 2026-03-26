package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

@TableName("template_plan_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TemplatePlanItem {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long templateId;

    private Integer dayNumber;
    private String taskText;
}
