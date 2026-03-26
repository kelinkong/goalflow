package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.goalflow.api.dto.DailyReviewCalendarDTO;
import com.goalflow.api.dto.DailyReviewDTO;
import com.goalflow.api.dto.DailyReviewItemDTO;
import com.goalflow.api.dto.DailyReviewUpsertRequest;
import com.goalflow.api.entity.DailyReview;
import com.goalflow.api.entity.DailyReviewItem;
import com.goalflow.api.entity.User;
import com.goalflow.api.exception.BusinessException;
import com.goalflow.api.mapper.DailyReviewItemMapper;
import com.goalflow.api.mapper.DailyReviewMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class DailyReviewService {
    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");
    private static final List<String> DIMENSION_ORDER = List.of(
            Dimension.WORK_STUDY.name(),
            Dimension.HEALTH.name(),
            Dimension.RELATIONSHIP.name(),
            Dimension.HOBBY.name()
    );

    private final DailyReviewMapper dailyReviewMapper;
    private final DailyReviewItemMapper dailyReviewItemMapper;

    public DailyReviewDTO getByDate(User user, String dateText) {
        LocalDate date = parseDate(dateText);
        DailyReview review = dailyReviewMapper.selectOne(new LambdaQueryWrapper<DailyReview>()
                .eq(DailyReview::getUserId, user.getId())
                .eq(DailyReview::getDate, date)
                .last("LIMIT 1"));
        if (review == null) {
            throw new BusinessException("指定日期的复盘不存在", 404);
        }
        return toDTO(review, loadItems(review.getId()));
    }

    @Transactional
    public DailyReviewDTO upsertByDate(User user, String dateText, DailyReviewUpsertRequest request) {
        LocalDate date = parseDate(dateText);
        validateRequest(request);

        DailyReview existing = dailyReviewMapper.selectOne(new LambdaQueryWrapper<DailyReview>()
                .eq(DailyReview::getUserId, user.getId())
                .eq(DailyReview::getDate, date)
                .last("LIMIT 1"));

        LocalDateTime now = LocalDateTime.now();
        Long reviewId;
        if (existing == null) {
            DailyReview review = DailyReview.builder()
                    .userId(user.getId())
                    .date(date)
                    .tomorrowTopPriority(request.getTomorrowTopPriority().trim())
                    .createdAt(now)
                    .updatedAt(now)
                    .build();
            dailyReviewMapper.insert(review);
            reviewId = review.getId();
        } else {
            reviewId = existing.getId();
            dailyReviewMapper.update(null, new LambdaUpdateWrapper<DailyReview>()
                    .eq(DailyReview::getId, reviewId)
                    .set(DailyReview::getTomorrowTopPriority, request.getTomorrowTopPriority().trim())
                    .set(DailyReview::getUpdatedAt, now));
            dailyReviewItemMapper.delete(new LambdaQueryWrapper<DailyReviewItem>()
                    .eq(DailyReviewItem::getReviewId, reviewId));
        }

        for (DailyReviewItemDTO item : request.getItems()) {
            dailyReviewItemMapper.insert(DailyReviewItem.builder()
                    .reviewId(reviewId)
                    .dimension(normalizeDimension(item.getDimension()))
                    .status(normalizeStatus(item.getStatus()))
                    .comment(item.getComment().trim())
                    .build());
        }

        DailyReview saved = dailyReviewMapper.selectById(reviewId);
        return toDTO(saved, loadItems(reviewId));
    }

    public DailyReviewCalendarDTO getCalendar(User user, String monthText) {
        YearMonth month = parseMonth(monthText);
        LocalDate start = month.atDay(1);
        LocalDate end = month.atEndOfMonth();
        List<DailyReview> reviews = dailyReviewMapper.selectList(new LambdaQueryWrapper<DailyReview>()
                .eq(DailyReview::getUserId, user.getId())
                .between(DailyReview::getDate, start, end)
                .orderByAsc(DailyReview::getDate));

        DailyReviewCalendarDTO dto = new DailyReviewCalendarDTO();
        dto.setMonth(month.format(MONTH_FORMATTER));
        dto.setReviewedDates(reviews.stream()
                .map(review -> review.getDate().toString())
                .toList());
        return dto;
    }

    private List<DailyReviewItem> loadItems(Long reviewId) {
        List<DailyReviewItem> items = dailyReviewItemMapper.selectList(new LambdaQueryWrapper<DailyReviewItem>()
                .eq(DailyReviewItem::getReviewId, reviewId));
        items.sort((a, b) -> Integer.compare(
                DIMENSION_ORDER.indexOf(a.getDimension()),
                DIMENSION_ORDER.indexOf(b.getDimension())
        ));
        return items;
    }

    private DailyReviewDTO toDTO(DailyReview review, List<DailyReviewItem> items) {
        DailyReviewDTO dto = new DailyReviewDTO();
        dto.setId(review.getId());
        dto.setDate(review.getDate());
        dto.setTomorrowTopPriority(review.getTomorrowTopPriority());
        dto.setCreatedAt(review.getCreatedAt());
        dto.setUpdatedAt(review.getUpdatedAt());
        dto.setItems(items.stream().map(this::toItemDTO).toList());
        return dto;
    }

    private DailyReviewItemDTO toItemDTO(DailyReviewItem item) {
        DailyReviewItemDTO dto = new DailyReviewItemDTO();
        dto.setDimension(item.getDimension());
        dto.setStatus(item.getStatus());
        dto.setComment(item.getComment());
        return dto;
    }

    private void validateRequest(DailyReviewUpsertRequest request) {
        if (request == null) {
            throw new BusinessException("复盘内容不能为空");
        }
        if (request.getTomorrowTopPriority() == null || request.getTomorrowTopPriority().trim().isEmpty()) {
            throw new BusinessException("明日最重要的事不能为空");
        }
        if (request.getItems() == null || request.getItems().size() != 4) {
            throw new BusinessException("每日复盘必须包含 4 个固定维度");
        }

        Set<String> dimensions = new LinkedHashSet<>();
        List<String> normalizedDimensions = new ArrayList<>();
        for (DailyReviewItemDTO item : request.getItems()) {
            if (item == null) {
                throw new BusinessException("复盘维度项不能为空");
            }
            String dimension = normalizeDimension(item.getDimension());
            String status = normalizeStatus(item.getStatus());
            if (item.getComment() == null || item.getComment().trim().isEmpty()) {
                throw new BusinessException("复盘备注不能为空");
            }
            dimensions.add(dimension);
            normalizedDimensions.add(dimension);
            item.setDimension(dimension);
            item.setStatus(status);
            item.setComment(item.getComment().trim());
        }

        if (dimensions.size() != 4 || !dimensions.containsAll(DIMENSION_ORDER)) {
            throw new BusinessException("每日复盘必须包含 4 个固定维度");
        }
    }

    private LocalDate parseDate(String dateText) {
        try {
            return LocalDate.parse(dateText);
        } catch (DateTimeParseException e) {
            throw new BusinessException("日期格式不正确，应为 yyyy-MM-dd");
        }
    }

    private YearMonth parseMonth(String monthText) {
        try {
            return YearMonth.parse(monthText, MONTH_FORMATTER);
        } catch (DateTimeParseException e) {
            throw new BusinessException("月份格式不正确，应为 yyyy-MM");
        }
    }

    private String normalizeDimension(String dimension) {
        if (dimension == null || dimension.trim().isEmpty()) {
            throw new BusinessException("复盘维度不能为空");
        }
        try {
            return Dimension.valueOf(dimension.trim().toUpperCase()).name();
        } catch (IllegalArgumentException e) {
            throw new BusinessException("复盘维度不合法");
        }
    }

    private String normalizeStatus(String status) {
        if (status == null || status.trim().isEmpty()) {
            throw new BusinessException("复盘状态不能为空");
        }
        try {
            return ReviewStatus.valueOf(status.trim().toUpperCase()).name();
        } catch (IllegalArgumentException e) {
            throw new BusinessException("复盘状态不合法");
        }
    }

    private enum Dimension {
        WORK_STUDY,
        HEALTH,
        RELATIONSHIP,
        HOBBY
    }

    private enum ReviewStatus {
        GOOD,
        NORMAL,
        BAD
    }
}
