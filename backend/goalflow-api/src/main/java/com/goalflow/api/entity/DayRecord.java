package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import java.time.LocalDate;
import java.util.List;

@TableName("day_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DayRecord {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long goalId;

    private LocalDate date;

    private Integer dayNumber; // day in the plan (0..totalDays-1)

    @TableField(exist = false)
    private List<TaskRecord> taskRecords;
}
