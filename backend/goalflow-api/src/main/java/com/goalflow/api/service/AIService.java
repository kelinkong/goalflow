package com.goalflow.api.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.goalflow.api.dto.GoalDecompositionDTO;
import com.goalflow.api.dto.GoalPhaseDTO;
import lombok.RequiredArgsConstructor; // Keep for potential future use or remove if fully manual
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class AIService {

    private static final Logger log = LoggerFactory.getLogger(AIService.class);

    @Value("${openai.api-key}")
    private String apiKey;

    @Value("${openai.base-url}")
    private String baseUrl;

    @Value("${openai.model}")
    private String model;

    @Value("${openai.decompose-model:qwen3.5-plus-2026-02-15}")
    private String decomposeModel;

    @Value("${openai.enable-search:true}")
    private boolean enableSearch;

    @Value("${openai.search-strategy:turbo}")
    private String searchStrategy;

    private final ObjectMapper objectMapper;
    private final WebClient.Builder webClientBuilder;

    public AIService(ObjectMapper objectMapper, WebClient.Builder webClientBuilder) {
        this.objectMapper = objectMapper;
        this.webClientBuilder = webClientBuilder;
    }

    public List<List<String>> decomposeGoal(String name, String description, Integer totalDays, String taskCount) {
        return decomposeGoalDetailed(name, description, totalDays, taskCount).getTaskPlan();
    }

    public GoalDecompositionDTO decomposeGoalDetailed(String name, String description, Integer totalDays, String taskCount) {
        TaskCountRange taskCountRange = resolveTaskCountRange(taskCount);
        String prompt = buildPrompt(name, description, totalDays, taskCountRange);
        int maxTokens = resolveDecomposeMaxTokens(totalDays, taskCountRange);

        Map<String, Object> request = new LinkedHashMap<>();
        request.put("model", decomposeModel);
        request.put("messages", List.of(
                Map.of("role", "user", "content", prompt)
        ));
        request.put("max_tokens", maxTokens);
        request.put("temperature", 0.6);
        request.put("enable_thinking", false);
        if (enableSearch) {
            request.put("enable_search", true);
            request.put("search_options", Map.of("forced_search", true, "search_strategy", searchStrategy));
        }

        long startedAt = System.currentTimeMillis();

        try {
            String response = webClientBuilder.baseUrl(baseUrl).build()
                .post()
                .uri("/chat/completions")
                .header("Authorization", "Bearer " + apiKey)
                .bodyValue(request)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            Map<String, Object> data = objectMapper.readValue(response, new TypeReference<>() {});
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> choices = (List<Map<String, Object>>) data.get("choices");
            Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
            String content = (String) message.get("content");

            String cleaned = content.replaceAll("```json|```", "").trim();
            GoalDecompositionDTO result;
            try {
                result = parseDecomposition(cleaned, totalDays, taskCountRange, name);
            } catch (Exception parseException) {
                log.warn("Falling back to partial AI decomposition parse model={} days={} taskCount={} reason={}",
                        decomposeModel, totalDays, taskCountRange.label(), parseException.getMessage());
                result = parsePartialDecomposition(cleaned, totalDays, taskCountRange, name);
            }
            if (result.getTaskPlan() == null || result.getTaskPlan().isEmpty()) {
                throw new RuntimeException("AI response empty");
            }
            long durationMs = System.currentTimeMillis() - startedAt;
            log.info("Goal decomposition finished with model={} days={} taskCount={} maxTokens={} searchEnabled={} duration={}ms",
                    decomposeModel, totalDays, taskCountRange.label(), maxTokens, enableSearch, durationMs);
            return result;

        } catch (Exception e) {
            long durationMs = System.currentTimeMillis() - startedAt;
            log.error("Failed to decompose goal with AI model={} days={} taskCount={} maxTokens={} searchEnabled={} duration={}ms",
                    decomposeModel, totalDays, taskCountRange.label(), maxTokens, enableSearch, durationMs, e);
            throw new RuntimeException("AI decomposition failed", e);
        }
    }

    private GoalDecompositionDTO parseDecomposition(String cleaned, Integer totalDays, TaskCountRange taskCountRange, String goalName) throws Exception {
        GoalDecompositionDTO result = new GoalDecompositionDTO();
        if (cleaned.startsWith("[")) {
            List<Map<String, Object>> days = objectMapper.readValue(cleaned, new TypeReference<>() {});
            result.setPhases(buildDefaultPhases(totalDays));
            result.setTaskPlan(normalizePlan(days, totalDays, taskCountRange, goalName));
            return result;
        }

        Map<String, Object> parsed = objectMapper.readValue(cleaned, new TypeReference<>() {});
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> rawPhases = (List<Map<String, Object>>) parsed.get("phases");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> rawDays = (List<Map<String, Object>>) parsed.get("days");

        result.setPhases(normalizePhases(rawPhases, totalDays));
        result.setTaskPlan(normalizePlan(rawDays, totalDays, taskCountRange, goalName));
        return result;
    }

    private GoalDecompositionDTO parsePartialDecomposition(String cleaned, Integer totalDays, TaskCountRange taskCountRange, String goalName) {
        GoalDecompositionDTO result = new GoalDecompositionDTO();
        result.setPhases(extractPartialPhases(cleaned, totalDays));
        result.setTaskPlan(extractPartialTaskPlan(cleaned, totalDays, taskCountRange, goalName));
        return result;
    }

    private List<GoalPhaseDTO> extractPartialPhases(String cleaned, Integer totalDays) {
        Pattern pattern = Pattern.compile("\\{\"title\":\"([^\"]+)\",\"startDay\":(\\d+),\"endDay\":(\\d+),\"focus\":\"([^\"]*)\"\\}");
        Matcher matcher = pattern.matcher(cleaned);
        List<GoalPhaseDTO> phases = new ArrayList<>();
        while (matcher.find()) {
            GoalPhaseDTO phase = new GoalPhaseDTO();
            phase.setTitle(matcher.group(1));
            phase.setStartDay(Integer.parseInt(matcher.group(2)));
            phase.setEndDay(Integer.parseInt(matcher.group(3)));
            phase.setFocus(matcher.group(4));
            phases.add(phase);
        }
        return phases.isEmpty() ? buildDefaultPhases(totalDays) : phases;
    }

    private List<List<String>> extractPartialTaskPlan(String cleaned, Integer totalDays, TaskCountRange taskCountRange, String goalName) {
        Pattern pattern = Pattern.compile("\\{\"day\":(\\d+),\"tasks\":\\[(.*?)\\]\\}");
        Matcher matcher = pattern.matcher(cleaned);
        List<Map<String, Object>> rawDays = new ArrayList<>();
        while (matcher.find()) {
            try {
                int day = Integer.parseInt(matcher.group(1));
                List<String> tasks = objectMapper.readValue("[" + matcher.group(2) + "]", new TypeReference<>() {});
                rawDays.add(Map.of("day", day, "tasks", tasks));
            } catch (Exception ignored) {
                // Skip malformed partial day entries and let normalizePlan fill the gaps.
            }
        }
        return normalizePlan(rawDays, totalDays, taskCountRange, goalName);
    }

    private List<List<String>> normalizePlan(List<Map<String, Object>> rawDays, Integer totalDays, TaskCountRange taskCountRange, String goalName) {
        List<List<String>> plan = new ArrayList<>();
        if (rawDays != null) {
            for (Map<String, Object> day : rawDays) {
                @SuppressWarnings("unchecked")
                List<String> tasks = (List<String>) day.get("tasks");
                plan.add(normalizeTasks(tasks, taskCountRange, plan.size() + 1, totalDays, goalName));
            }
        }
        if (plan.isEmpty()) {
            plan.addAll(buildDefaultTaskPlan(totalDays, taskCountRange, goalName));
        }
        if (plan.size() > totalDays) {
            plan = new ArrayList<>(plan.subList(0, totalDays));
        }
        while (plan.size() < totalDays) {
            plan.add(buildFallbackTasks(taskCountRange, plan.size() + 1, totalDays, goalName));
        }
        return plan;
    }

    private List<GoalPhaseDTO> normalizePhases(List<Map<String, Object>> rawPhases, Integer totalDays) {
        if (rawPhases == null || rawPhases.isEmpty()) {
            return buildDefaultPhases(totalDays);
        }
        List<GoalPhaseDTO> phases = new ArrayList<>();
        for (Map<String, Object> raw : rawPhases) {
            GoalPhaseDTO phase = new GoalPhaseDTO();
            phase.setTitle(raw.getOrDefault("title", "阶段").toString());
            phase.setStartDay(((Number) raw.getOrDefault("startDay", 1)).intValue());
            phase.setEndDay(((Number) raw.getOrDefault("endDay", totalDays)).intValue());
            phase.setFocus(raw.getOrDefault("focus", "").toString());
            phases.add(phase);
        }
        return phases;
    }

    private List<GoalPhaseDTO> buildDefaultPhases(Integer totalDays) {
        int warmupDays = Math.max(2, totalDays / 5);
        int sprintDays = Math.max(2, totalDays / 5);
        int buildEndDay = Math.max(warmupDays + 1, totalDays - sprintDays);

        GoalPhaseDTO p1 = new GoalPhaseDTO();
        p1.setTitle("起步期");
        p1.setStartDay(1);
        p1.setEndDay(warmupDays);
        p1.setFocus("降低门槛，建立节奏，先完成关键准备动作");

        GoalPhaseDTO p2 = new GoalPhaseDTO();
        p2.setTitle("积累期");
        p2.setStartDay(warmupDays + 1);
        p2.setEndDay(buildEndDay);
        p2.setFocus("稳定推进，逐步加量，形成连续输出");

        GoalPhaseDTO p3 = new GoalPhaseDTO();
        p3.setTitle("强化期");
        p3.setStartDay(buildEndDay + 1);
        p3.setEndDay(totalDays);
        p3.setFocus("查缺补漏，强化结果，完成总结或实战检验");

        return List.of(p1, p2, p3);
    }

    private List<List<String>> buildDefaultTaskPlan(Integer totalDays, TaskCountRange taskCountRange, String goalName) {
        List<List<String>> plan = new ArrayList<>();
        for (int day = 1; day <= totalDays; day++) {
            plan.add(buildFallbackTasks(taskCountRange, day, totalDays, goalName));
        }
        return plan;
    }

    private String buildPrompt(String name, String description, Integer totalDays, TaskCountRange taskCountRange) {
        int warmupDays = Math.max(2, totalDays / 5);
        int sprintDays = Math.max(2, totalDays / 5);
        int buildEndDay = Math.max(warmupDays + 1, totalDays - sprintDays);
        String currentLevel = (description == null || description.isBlank()) ? "未提供，请按新手到初级水平谨慎规划" : description.trim();

        return String.format("""
                你要把一个目标拆成“阶段计划 + 每日任务”。
                你已经开启联网搜索，必须先搜索与这个目标最相关的真实经验，再生成计划。
                只返回紧凑 JSON 对象，不要 markdown，不要解释，不要代码块，不要额外换行。

                用户目标：%s
                用户当前基础：%s
                计划周期：%d 天
                用户偏好的每日任务量：%s（每天 %d-%d 条）

                搜索要求：
                1. 先搜索这个目标对应的备考心得、常见误区、高频建议、推荐训练顺序、资料使用方式。
                2. 优先参考真实经验型内容，例如备考贴、复盘贴、通过经验、学习方法总结。
                3. 先从搜索结果里提炼 3-5 条真正有执行价值的方法，再据此安排阶段和每日任务。
                4. 不要把搜索结果原样复述成空话，要把它改写成今天就能执行的动作。
                5. 如果用户目标是考试、证书、学习提升，任务里要体现真实备考路径，比如输入、练习、输出、复盘、错题整理、模拟训练。
                6. 优先把检索出的有效策略落实到计划里，而不是套用通用学习模板。

                约束：
                1. 必须分为 3 个阶段：起步期、积累期、强化期。
                2. 前 %d 天是起步期：降低门槛，建立环境和节奏。
                3. 第 %d 天到第 %d 天是积累期：稳定推进，开始连续产出。
                4. 最后 %d 天是强化期：总结、输出、复盘、查缺补漏或模拟实战。
                5. 每天任务控制在 %d-%d 条之间。
                6. 任务必须具体、可执行、最好有动作或产出。
                7. 不要写空话，例如“继续努力”“保持状态”“坚持打卡”。
                8. 前几天更重准备和建立节奏，后几天更重输出和复盘。
                9. 如果搜索结果显示某类方法更有效，计划里要明显体现这种方法，而不是平均分配任务。
                10. 每日任务数量不要固定不变，要循序渐进：起步期靠近下限，积累期逐步增加，强化期靠近上限。
                11. 同一天的任务类型尽量有变化，例如输入、练习、输出、复盘，而不是都写成同一种句式。
                12. 相邻两天不要重复同一句任务，除非是在推进同一策略的下一步动作。
                13. 如果同一类训练需要多天持续推进，也要写成不同侧重点，而不是简单重复改几个字。

                返回格式：
                {
                  "phases": [
                    {"title":"起步期","startDay":1,"endDay":7,"focus":"说明这一阶段要完成什么"},
                    {"title":"积累期","startDay":8,"endDay":24,"focus":"说明这一阶段要完成什么"},
                    {"title":"强化期","startDay":25,"endDay":30,"focus":"说明这一阶段要完成什么"}
                  ],
                  "days": [
                    {"day":1,"tasks":["任务1","任务2"]},
                    {"day":2,"tasks":["任务1","任务2"]},
                    {"day":3,"tasks":["任务1","任务2"]}
                  ]
                }
                """,
                name,
                currentLevel,
                totalDays,
                taskCountRange.label(),
                taskCountRange.min(),
                taskCountRange.max(),
                warmupDays,
                warmupDays + 1,
                buildEndDay,
                sprintDays,
                taskCountRange.min(),
                taskCountRange.max());
    }

    private int resolveDecomposeMaxTokens(Integer totalDays, TaskCountRange taskCountRange) {
        int estimated = totalDays * taskCountRange.max() * 28 + 500;
        return Math.max(2200, Math.min(4200, estimated));
    }

    private List<String> normalizeTasks(List<String> tasks, TaskCountRange taskCountRange, int dayNumber, int totalDays, String goalName) {
        int targetCount = resolveTargetTaskCount(taskCountRange, dayNumber, totalDays);
        if (tasks == null) {
            return buildFallbackTasks(taskCountRange, dayNumber, totalDays, goalName);
        }
        List<String> cleaned = tasks.stream()
                .filter(task -> task != null && !task.isBlank())
                .map(String::trim)
                .map(task -> task.replaceFirst("^[0-9一二三四五六七八九十]+[\\.、\\s]*", ""))
                .filter(task -> !isGenericTask(task))
                .distinct()
                .collect(Collectors.toCollection(ArrayList::new));

        if (cleaned.size() > taskCountRange.max()) {
            cleaned = new ArrayList<>(cleaned.subList(0, taskCountRange.max()));
        }
        while (cleaned.size() < targetCount) {
            cleaned.add(buildSupportTask(dayNumber, totalDays, goalName, cleaned.size()));
        }
        return cleaned;
    }

    private List<String> buildFallbackTasks(TaskCountRange taskCountRange, int dayNumber, int totalDays, String goalName) {
        List<String> tasks = new ArrayList<>();
        int targetCount = resolveTargetTaskCount(taskCountRange, dayNumber, totalDays);
        for (int i = 0; i < targetCount; i++) {
            tasks.add(buildSupportTask(dayNumber, totalDays, goalName, i));
        }
        return tasks;
    }

    private int resolveTargetTaskCount(TaskCountRange taskCountRange, int dayNumber, int totalDays) {
        if (taskCountRange.min() >= taskCountRange.max() || totalDays <= 1) {
            return taskCountRange.min();
        }
        double progress = (dayNumber - 1D) / Math.max(1D, totalDays - 1D);
        int span = taskCountRange.max() - taskCountRange.min();
        int target = taskCountRange.min() + (int) Math.round(progress * span);
        return Math.max(taskCountRange.min(), Math.min(taskCountRange.max(), target));
    }

    private String buildSupportTask(int dayNumber, int totalDays, String goalName, int index) {
        List<String> earlyTasks = List.of(
                "梳理“" + goalName + "”关键模块并标出薄弱项",
                "完成一次入门练习并记录主要卡点",
                "整理今天使用的资料并写简短笔记",
                "围绕核心主题做一轮基础巩固",
                "参考范例完成一次模仿输出"
        );
        List<String> middleTasks = List.of(
                "完成一次专项训练并整理错因",
                "精练重点模块并补充易错点",
                "围绕高频内容做应用练习",
                "限时完成一轮训练并复盘节奏",
                "把今天内容整理成一页复盘笔记"
        );
        List<String> lateTasks = List.of(
                "完成一次限时模拟并统计薄弱点",
                "整理高频错因并逐条订正",
                "输出一份总结卡片并进行复述",
                "补练薄弱模块并观察改进情况",
                "根据今天结果写出明天的调整动作"
        );
        List<String> source = dayNumber <= Math.max(2, totalDays / 4)
                ? earlyTasks
                : dayNumber >= Math.max(3, totalDays - Math.max(2, totalDays / 4) + 1)
                    ? lateTasks
                    : middleTasks;
        return source.get(index % source.size());
    }

    private boolean isGenericTask(String task) {
        String normalized = task.replace(" ", "");
        return normalized.contains("继续努力")
                || normalized.contains("保持状态")
                || normalized.contains("坚持打卡")
                || normalized.contains("继续学习")
                || normalized.contains("完成今天任务")
                || normalized.length() <= 6;
    }

    private TaskCountRange resolveTaskCountRange(String taskCount) {
        if (taskCount == null) {
            return new TaskCountRange("中", 2, 4);
        }
        return switch (taskCount.trim()) {
            case "少" -> new TaskCountRange("少", 1, 2);
            case "多" -> new TaskCountRange("多", 4, 6);
            default -> new TaskCountRange("中", 2, 4);
        };
    }

    private record TaskCountRange(String label, int min, int max) {}
}
