package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@TableName("templates")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Template {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long ownerId;

    private String name;
    private String description;
    
    private Integer totalDays;

    private String visibility; // PRIVATE, PUBLIC
    private String tags;
    
    private String status; // PENDING, APPROVED, REJECTED
    private LocalDateTime reviewedAt;
    private Long reviewedBy;
    private String rejectReason;

    private LocalDateTime createdAt;

    @TableField(exist = false)
    private List<TemplatePlanItem> planItems;
}
