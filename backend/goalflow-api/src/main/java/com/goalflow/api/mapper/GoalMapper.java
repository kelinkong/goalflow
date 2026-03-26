package com.goalflow.api.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.goalflow.api.entity.Goal;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface GoalMapper extends BaseMapper<Goal> {}
