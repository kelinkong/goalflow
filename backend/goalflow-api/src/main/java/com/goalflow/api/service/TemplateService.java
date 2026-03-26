package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.goalflow.api.dto.TemplateCreateRequest;
import com.goalflow.api.dto.TemplateDTO;
import com.goalflow.api.entity.Template;
import com.goalflow.api.entity.TemplatePlanItem;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.TemplateMapper;
import com.goalflow.api.mapper.TemplatePlanItemMapper;
import com.goalflow.api.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TemplateService {
    private final TemplateMapper templateMapper;
    private final TemplatePlanItemMapper templatePlanItemMapper;
    private final UserMapper userMapper;
    private final EntityValidationService validationService;

    public TemplateDTO createTemplate(User user, TemplateCreateRequest request) {
        if (request.getTaskPlan() == null || request.getTaskPlan().isEmpty()) {
            throw new RuntimeException("taskPlan is required");
        }
        boolean requestPublic = "PUBLIC".equalsIgnoreCase(normalizeVisibility(request.getVisibility()));
        Template template = Template.builder()
                .ownerId(user.getId())
                .name(request.getName())
                .description(request.getDescription())
                .totalDays(request.getTotalDays() == null ? request.getTaskPlan().size() : request.getTotalDays())
                .visibility("PRIVATE")
                .tags(request.getTags())
                .status(requestPublic ? "PENDING" : "DRAFT")
                .createdAt(LocalDateTime.now())
                .build();
        templateMapper.insert(template);

        insertPlanItems(template.getId(), request.getTaskPlan());
        return getTemplateForUser(user, template.getId());
    }

    public List<TemplateDTO> getPublicTemplates() {
        List<Template> templates = templateMapper.selectList(
                new LambdaQueryWrapper<Template>()
                        .eq(Template::getVisibility, "PUBLIC")
                        .eq(Template::getStatus, "APPROVED")
        );
        return toDTOs(templates);
    }

    public List<TemplateDTO> getMyTemplates(User user) {
        List<Template> templates = templateMapper.selectList(
                new LambdaQueryWrapper<Template>().eq(Template::getOwnerId, user.getId())
        );
        return toDTOs(templates);
    }

    public TemplateDTO getTemplateForUser(User user, Long templateId) {
        return toDTO(requireUsableTemplate(user, templateId));
    }

    public Template publishTemplate(User user, Long templateId) {
        Template template = validationService.requireOwnedTemplate(user.getId(), templateId);
        template.setVisibility("PRIVATE");
        template.setStatus("PENDING");
        template.setReviewedAt(null);
        template.setReviewedBy(null);
        template.setRejectReason(null);
        templateMapper.updateById(template);
        return template;
    }

    public Template requireUsableTemplate(User user, Long templateId) {
        Template template = templateMapper.selectById(templateId);
        if (template == null) {
            throw new RuntimeException("Template not found");
        }
        boolean isOwner = user.getId().equals(template.getOwnerId());
        boolean isPublic = "PUBLIC".equalsIgnoreCase(template.getVisibility());
        if (!isOwner && !isPublic) {
            throw new RuntimeException("Template not accessible");
        }
        template.setPlanItems(getPlanItems(List.of(templateId)).getOrDefault(templateId, List.of()));
        return template;
    }

    private List<TemplateDTO> toDTOs(List<Template> templates) {
        if (templates.isEmpty()) {
            return Collections.emptyList();
        }
        List<Long> templateIds = templates.stream().map(Template::getId).toList();
        Map<Long, List<TemplatePlanItem>> planByTemplate = getPlanItems(templateIds);
        Map<Long, String> ownerNames = userMapper.selectBatchIds(
                        templates.stream().map(Template::getOwnerId).distinct().toList()
                ).stream()
                .collect(Collectors.toMap(User::getId, user -> {
                    if (user.getNickname() != null && !user.getNickname().isBlank()) {
                        return user.getNickname();
                    }
                    return user.getEmail();
                }));

        return templates.stream().map(template -> {
            template.setPlanItems(planByTemplate.getOrDefault(template.getId(), List.of()));
            TemplateDTO dto = toDTO(template);
            dto.setOwnerNickname(ownerNames.get(template.getOwnerId()));
            return dto;
        }).toList();
    }

    private TemplateDTO toDTO(Template template) {
        List<TemplatePlanItem> planItems = template.getPlanItems() == null
                ? List.of()
                : template.getPlanItems();
        Map<Integer, List<String>> planMap = planItems.stream()
                .collect(Collectors.groupingBy(
                        TemplatePlanItem::getDayNumber,
                        Collectors.mapping(TemplatePlanItem::getTaskText, Collectors.toList())
                ));
        List<List<String>> taskPlan = new ArrayList<>();
        for (int i = 0; i < template.getTotalDays(); i++) {
            taskPlan.add(planMap.getOrDefault(i, List.of()));
        }

        TemplateDTO dto = new TemplateDTO();
        dto.setId(template.getId());
        dto.setOwnerId(template.getOwnerId());
        dto.setName(template.getName());
        dto.setDescription(template.getDescription());
        dto.setTotalDays(template.getTotalDays());
        dto.setVisibility(template.getVisibility());
        dto.setStatus(template.getStatus());
        dto.setTags(template.getTags());
        dto.setCreatedAt(template.getCreatedAt());
        dto.setTaskPlan(taskPlan);
        dto.setTotalTasks(taskPlan.stream().mapToInt(List::size).sum());
        return dto;
    }

    private void insertPlanItems(Long templateId, List<List<String>> plan) {
        List<TemplatePlanItem> items = new ArrayList<>();
        for (int i = 0; i < plan.size(); i++) {
            for (String task : plan.get(i)) {
                items.add(TemplatePlanItem.builder()
                        .templateId(templateId)
                        .dayNumber(i)
                        .taskText(task)
                        .build());
            }
        }
        for (TemplatePlanItem item : items) {
            templatePlanItemMapper.insert(item);
        }
    }

    private Map<Long, List<TemplatePlanItem>> getPlanItems(List<Long> templateIds) {
        if (templateIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return templatePlanItemMapper.selectList(
                new LambdaQueryWrapper<TemplatePlanItem>().in(TemplatePlanItem::getTemplateId, templateIds)
        ).stream().collect(Collectors.groupingBy(TemplatePlanItem::getTemplateId));
    }

    private String normalizeVisibility(String visibility) {
        if (visibility == null || visibility.isBlank()) {
            return "PRIVATE";
        }
        return visibility.toUpperCase();
    }
}
