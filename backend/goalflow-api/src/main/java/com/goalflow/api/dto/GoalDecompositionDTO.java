package com.goalflow.api.dto;

import java.util.List;

public class GoalDecompositionDTO {
    private List<GoalPhaseDTO> phases;
    private List<List<String>> taskPlan;

    public List<GoalPhaseDTO> getPhases() {
        return phases;
    }

    public void setPhases(List<GoalPhaseDTO> phases) {
        this.phases = phases;
    }

    public List<List<String>> getTaskPlan() {
        return taskPlan;
    }

    public void setTaskPlan(List<List<String>> taskPlan) {
        this.taskPlan = taskPlan;
    }
}
