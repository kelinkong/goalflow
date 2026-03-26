package com.goalflow.api.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;
import java.time.LocalDateTime;

@TableName("task_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskRecord {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long dayRecordId;

    private Integer taskIndex;
    private String taskText;

    private boolean isDone;
    private boolean isDeferred;
    private boolean isMakeup;
    private LocalDateTime doneAt;
    private String deferredTo; // date as string
}
