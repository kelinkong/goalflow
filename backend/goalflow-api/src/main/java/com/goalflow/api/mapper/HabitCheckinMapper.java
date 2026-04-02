package com.goalflow.api.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.goalflow.api.entity.HabitCheckin;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface HabitCheckinMapper extends BaseMapper<HabitCheckin> {

    @Insert("INSERT INTO habit_checkins (habit_id, user_id, date, is_done, created_at, updated_at) " +
            "VALUES (#{c.habitId}, #{c.userId}, #{c.date}, #{c.isDone}, #{c.createdAt}, #{c.updatedAt}) " +
            "ON DUPLICATE KEY UPDATE is_done = VALUES(is_done), updated_at = VALUES(updated_at)")
    int upsert(@Param("c") HabitCheckin checkin);
}
