/*
 * Copyright (c) 2026 GoalFlow Contributors
 * Licensed under the MIT License. See LICENSE file in the project root for full license information.
 */
package com.goalflow.api;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@org.springframework.scheduling.annotation.EnableAsync
@MapperScan("com.goalflow.api.mapper")
public class ApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(ApiApplication.class, args);
    }
}
