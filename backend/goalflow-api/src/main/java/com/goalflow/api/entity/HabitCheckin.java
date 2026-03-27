package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@TableName("habit_checkins")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HabitCheckin {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long habitId;

    private Long userId;

    private LocalDate date;

    private Boolean isDone;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
