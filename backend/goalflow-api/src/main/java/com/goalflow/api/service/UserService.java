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
            if (trimmedAvatar.length() > 5_000_000) {
                throw new BusinessException("头像图片数据过大", 400);
            }
            
            if (trimmedAvatar.contains(",")) {
                trimmedAvatar = trimmedAvatar.substring(trimmedAvatar.indexOf(",") + 1);
            }
            
            if (!trimmedAvatar.isEmpty()) {
                try {
                    // 解码 Base64
                    byte[] imageBytes = java.util.Base64.getDecoder().decode(trimmedAvatar);
                    // 生成文件名：avatar_用户ID.jpg (简单处理)
                    String fileName = "avatar_" + user.getId() + "_" + System.currentTimeMillis() + ".jpg";
                    String relativePath = "/uploads/avatars/" + fileName;
                    
                    // 确保目录存在 (容器内的路径)
                    java.io.File uploadDir = new java.io.File("/app/uploads/avatars");
                    if (!uploadDir.exists()) uploadDir.mkdirs();
                    
                    // 写入磁盘
                    java.nio.file.Files.write(java.nio.file.Paths.get("/app/uploads/avatars/", fileName), imageBytes);
                    
                    user.setAvatar(relativePath); 
                } catch (Exception e) {
                    throw new BusinessException("头像保存失败: " + e.getMessage(), 500);
                }
            } else {
                user.setAvatar(null);
            }
            changed = true;
        }

        if (!changed) {
            return user;
        }

        userMapper.updateById(user);
        return userMapper.selectById(user.getId());
    }
}
