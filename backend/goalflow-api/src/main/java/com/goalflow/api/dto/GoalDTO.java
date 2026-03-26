package com.goalflow.api.dto;

import java.time.LocalDateTime;
import java.util.List;

public class GoalDTO {
    private String id;
    private String name;
    private String emoji;
    private String description;
    private Integer totalDays;
    private Long templateId;
    private Boolean joinRanking;
    private String status;
    private String taskCount;
    private LocalDateTime createdAt;
    private List<List<String>> taskPlan;

    public GoalDTO() {}

    public GoalDTO(String id, String name, String emoji, String description, Integer totalDays, Long templateId, Boolean joinRanking, String status, String taskCount, LocalDateTime createdAt, List<List<String>> taskPlan) {
        this.id = id;
        this.name = name;
        this.emoji = emoji;
        this.description = description;
        this.totalDays = totalDays;
        this.templateId = templateId;
        this.joinRanking = joinRanking;
        this.status = status;
        this.taskCount = taskCount;
        this.createdAt = createdAt;
        this.taskPlan = taskPlan;
    }

    public static GoalDTOBuilder builder() {
        return new GoalDTOBuilder();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getEmoji() { return emoji; }
    public void setEmoji(String emoji) { this.emoji = emoji; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Integer getTotalDays() { return totalDays; }
    public void setTotalDays(Integer totalDays) { this.totalDays = totalDays; }
    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }
    public Boolean getJoinRanking() { return joinRanking; }
    public void setJoinRanking(Boolean joinRanking) { this.joinRanking = joinRanking; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getTaskCount() { return taskCount; }
    public void setTaskCount(String taskCount) { this.taskCount = taskCount; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public List<List<String>> getTaskPlan() { return taskPlan; }
    public void setTaskPlan(List<List<String>> taskPlan) { this.taskPlan = taskPlan; }

    public static class GoalDTOBuilder {
        private String id;
        private String name;
        private String emoji;
        private String description;
        private Integer totalDays;
        private Long templateId;
        private Boolean joinRanking;
        private String status;
        private String taskCount;
        private LocalDateTime createdAt;
        private List<List<String>> taskPlan;

        public GoalDTOBuilder id(String id) { this.id = id; return this; }
        public GoalDTOBuilder name(String name) { this.name = name; return this; }
        public GoalDTOBuilder emoji(String emoji) { this.emoji = emoji; return this; }
        public GoalDTOBuilder description(String description) { this.description = description; return this; }
        public GoalDTOBuilder totalDays(Integer totalDays) { this.totalDays = totalDays; return this; }
        public GoalDTOBuilder templateId(Long templateId) { this.templateId = templateId; return this; }
        public GoalDTOBuilder joinRanking(Boolean joinRanking) { this.joinRanking = joinRanking; return this; }
        public GoalDTOBuilder status(String status) { this.status = status; return this; }
        public GoalDTOBuilder taskCount(String taskCount) { this.taskCount = taskCount; return this; }
        public GoalDTOBuilder createdAt(LocalDateTime createdAt) { this.createdAt = createdAt; return this; }
        public GoalDTOBuilder taskPlan(List<List<String>> taskPlan) { this.taskPlan = taskPlan; return this; }
        public GoalDTO build() { return new GoalDTO(id, name, emoji, description, totalDays, templateId, joinRanking, status, taskCount, createdAt, taskPlan); }
    }
}
