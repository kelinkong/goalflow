import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, jsonHeaders, logFailure, setupAuth } from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 1 },
    { duration: '1m', target: 5 }, // AI 接口不要压太高并发，容易被大模型服务商限流
    { duration: '30s', target: 0 },
  ],
};

// 1. 启动前先登录
export const setup = setupAuth;

export default function (data) {
  const payload = {
    name: `k6 decompose ${__VU}-${__ITER}`,
    description: 'load test for AI decomposition endpoint',
    totalDays: 7,
    taskCount: 'LIGHT',
  };

  // 2. 携带 Token 发起请求
  const res = http.post(`${BASE_URL}/goals/decompose`, JSON.stringify(payload), {
    headers: jsonHeaders(data.token),
    timeout: __ENV.AI_TIMEOUT || '60s',
  });

  check(res, {
    'decompose status is 200': (r) => r.status === 200,
  });

  if (res.status !== 200) {
    logFailure('goal decompose', res);
  }

  // AI 接口比较慢，休息久一点
  sleep(5);
}
