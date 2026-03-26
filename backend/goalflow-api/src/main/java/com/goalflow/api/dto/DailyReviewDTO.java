package com.goalflow.api.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public class DailyReviewDTO {
    private Long id;
    private LocalDate date;
    private String tomorrowTopPriority;
    private List<DailyReviewItemDTO> items;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
