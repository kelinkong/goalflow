package com.goalflow.api.dto;

import java.time.LocalDateTime;

public class MedalDTO {
    private Long id;
    private Long goalId;
    private String goalName;
    private String goalEmoji;
    private String title;
    private LocalDateTime awardedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getGoalId() {
        return goalId;
    }

    public void setGoalId(Long goalId) {
        this.goalId = goalId;
    }

    public String getGoalName() {
        return goalName;
    }

    public void setGoalName(String goalName) {
        this.goalName = goalName;
    }

    public String getGoalEmoji() {
        return goalEmoji;
    }

    public void setGoalEmoji(String goalEmoji) {
        this.goalEmoji = goalEmoji;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public LocalDateTime getAwardedAt() {
        return awardedAt;
    }

    public void setAwardedAt(LocalDateTime awardedAt) {
        this.awardedAt = awardedAt;
    }
}
