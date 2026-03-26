package com.goalflow.api.dto;

public class TaskActionRequest {
    private String sourceDate;
    private Integer taskIndex;
    private String targetDate;
    private Boolean isMakeup;
    private Boolean done;

    public String getSourceDate() {
        return sourceDate;
    }

    public void setSourceDate(String sourceDate) {
        this.sourceDate = sourceDate;
    }

    public Integer getTaskIndex() {
        return taskIndex;
    }

    public void setTaskIndex(Integer taskIndex) {
        this.taskIndex = taskIndex;
    }

    public String getTargetDate() {
        return targetDate;
    }

    public void setTargetDate(String targetDate) {
        this.targetDate = targetDate;
    }

    public Boolean getIsMakeup() {
        return isMakeup;
    }

    public void setIsMakeup(Boolean makeup) {
        isMakeup = makeup;
    }

    public Boolean getDone() {
        return done;
    }

    public void setDone(Boolean done) {
        this.done = done;
    }
}
