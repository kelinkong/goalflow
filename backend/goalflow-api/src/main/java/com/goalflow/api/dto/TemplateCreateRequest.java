package com.goalflow.api.dto;

import java.util.List;

public class TemplateCreateRequest {
    private String name;
    private String description;
    private Integer totalDays;
    private String visibility;
    private String tags;
    private List<List<String>> taskPlan;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getTotalDays() {
        return totalDays;
    }

    public void setTotalDays(Integer totalDays) {
        this.totalDays = totalDays;
    }

    public String getVisibility() {
        return visibility;
    }

    public void setVisibility(String visibility) {
        this.visibility = visibility;
    }

    public String getTags() {
        return tags;
    }

    public void setTags(String tags) {
        this.tags = tags;
    }

    public List<List<String>> getTaskPlan() {
        return taskPlan;
    }

    public void setTaskPlan(List<List<String>> taskPlan) {
        this.taskPlan = taskPlan;
    }
}
