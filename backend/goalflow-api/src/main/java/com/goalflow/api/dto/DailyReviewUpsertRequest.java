package com.goalflow.api.dto;

import java.util.List;

public class DailyReviewUpsertRequest {
    private String tomorrowTopPriority;
    private List<DailyReviewItemDTO> items;

    public String getTomorrowTopPriority() {
        return tomorrowTopPriority;
    }

    public void setTomorrowTopPriority(String tomorrowTopPriority) {
        this.tomorrowTopPriority = tomorrowTopPriority;
    }

    public List<DailyReviewItemDTO> getItems() {
        return items;
    }

    public void setItems(List<DailyReviewItemDTO> items) {
        this.items = items;
    }
}
