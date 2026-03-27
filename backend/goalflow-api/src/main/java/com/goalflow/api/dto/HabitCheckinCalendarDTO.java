package com.goalflow.api.dto;

import java.util.List;

public class HabitCheckinCalendarDTO {
    private String month;
    private List<HabitCheckinDTO> checkins;

    public String getMonth() {
        return month;
    }

    public void setMonth(String month) {
        this.month = month;
    }

    public List<HabitCheckinDTO> getCheckins() {
        return checkins;
    }

    public void setCheckins(List<HabitCheckinDTO> checkins) {
        this.checkins = checkins;
    }
}
