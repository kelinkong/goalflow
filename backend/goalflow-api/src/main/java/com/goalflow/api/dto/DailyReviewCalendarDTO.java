package com.goalflow.api.dto;

import java.util.List;

public class DailyReviewCalendarDTO {
    private String month;
    private List<String> reviewedDates;

    public String getMonth() {
        return month;
    }

    public void setMonth(String month) {
        this.month = month;
    }

    public List<String> getReviewedDates() {
        return reviewedDates;
    }

    public void setReviewedDates(List<String> reviewedDates) {
        this.reviewedDates = reviewedDates;
    }
}
