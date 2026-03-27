package com.goalflow.api.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.goalflow.api.exception.BusinessException;
import com.goalflow.api.entity.User;
import com.goalflow.api.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserMapper userMapper;

    public User findByEmail(String email) {
        return userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getEmail, email));
    }

    public User requireByEmail(String email) {
        User user = findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }
        return user;
    }

    public User updateProfile(User user, String nickname, String avatar) {
        boolean changed = false;

        if (nickname != null) {
            String trimmedNickname = nickname.trim();
            if (trimmedNickname.isEmpty()) {
                throw new BusinessException("昵称不能为空", 400);
            }
            if (trimmedNickname.length() > 20) {
                throw new BusinessException("昵称不能超过 20 个字符", 400);
            }
            user.setNickname(trimmedNickname);
            changed = true;
        }

        if (avatar != null) {
            String trimmedAvatar = avatar.trim();
            // 放宽限制到 5MB (Base64 编码后)
            if (trimmedAvatar.length() > 5_000_000) {
                throw new BusinessException("头像图片数据过大", 400);
            }
            
            // 自动移除 Data URL 前缀 (如 data:image/jpeg;base64,)
            if (trimmedAvatar.contains(",")) {
                trimmedAvatar = trimmedAvatar.substring(trimmedAvatar.indexOf(",") + 1);
            }
            
            user.setAvatar(trimmedAvatar.isEmpty() ? null : trimmedAvatar);
            changed = true;
        }

        if (!changed) {
            return user;
        }

        userMapper.updateById(user);
        return userMapper.selectById(user.getId());
    }
}
