package com.goalflow.api.dto;

import java.util.List;

public class TimelineDayDTO {
    private String date;
    private Integer dayNumber;
    private List<TimelineTaskDTO> tasks;

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public Integer getDayNumber() {
        return dayNumber;
    }

    public void setDayNumber(Integer dayNumber) {
        this.dayNumber = dayNumber;
    }

    public List<TimelineTaskDTO> getTasks() {
        return tasks;
    }

    public void setTasks(List<TimelineTaskDTO> tasks) {
        this.tasks = tasks;
    }
}
