import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, REQUEST_TIMEOUT, jsonHeaders, logFailure, setupAuth } from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 100 },
    { duration: '1m', target: 500 },
    { duration: '30s', target: 0 },
  ],
};

export const setup = setupAuth;

export default function (data) {
  const res = http.get(`${BASE_URL}/goals`, {
    headers: jsonHeaders(data.token),
    timeout: REQUEST_TIMEOUT,
  });

  check(res, {
    'goals status is 200': (r) => r.status === 200,
    'goals body exists': (r) => r.body && r.body.length > 0,
  });

  if (res.status !== 200) {
    logFailure('goals list', res);
  }

  // 缩短 sleep，模拟更高频的访问压力
  sleep(0.5);
}
