package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import java.time.LocalDateTime;

@TableName("medals")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Medal {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long goalId;

    private String title;
    private LocalDateTime awardedAt;
}
