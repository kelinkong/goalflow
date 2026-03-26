package com.goalflow.api.dto;

public class TimelineTaskDTO {
    private Integer taskIndex;
    private String sourceDate;
    private String text;
    private boolean done;
    private boolean deferred;
    private boolean makeup;

    public Integer getTaskIndex() {
        return taskIndex;
    }

    public void setTaskIndex(Integer taskIndex) {
        this.taskIndex = taskIndex;
    }

    public String getSourceDate() {
        return sourceDate;
    }

    public void setSourceDate(String sourceDate) {
        this.sourceDate = sourceDate;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public boolean isDone() {
        return done;
    }

    public void setDone(boolean done) {
        this.done = done;
    }

    public boolean isDeferred() {
        return deferred;
    }

    public void setDeferred(boolean deferred) {
        this.deferred = deferred;
    }

    public boolean isMakeup() {
        return makeup;
    }

    public void setMakeup(boolean makeup) {
        this.makeup = makeup;
    }
}
