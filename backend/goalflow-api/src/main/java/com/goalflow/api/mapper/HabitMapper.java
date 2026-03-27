package com.goalflow.api.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.goalflow.api.entity.Habit;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface HabitMapper extends BaseMapper<Habit> {}
