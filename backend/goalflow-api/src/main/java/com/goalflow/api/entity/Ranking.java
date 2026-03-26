package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import java.time.LocalDateTime;

@TableName("rankings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Ranking {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long templateId;

    private Long userId;

    private Integer progressPercent;
    private Integer previousRank;
    private LocalDateTime updatedAt;
}
