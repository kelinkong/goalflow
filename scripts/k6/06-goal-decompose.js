import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, REQUEST_TIMEOUT, logFailure } from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 1 },
    { duration: '1m', target: 5 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const payload = {
    name: `k6 decompose ${__VU}-${__ITER}`,
    description: 'load test for AI decomposition endpoint',
    totalDays: 7,
    taskCount: 'LIGHT',
  };

  const res = http.post(`${BASE_URL}/goals/decompose`, JSON.stringify(payload), {
    headers: { 'Content-Type': 'application/json' },
    timeout: __ENV.AI_TIMEOUT || '60s',
  });

  check(res, {
    'decompose status is 200': (r) => r.status === 200,
  });

  if (res.status !== 200) {
    logFailure('goal decompose', res);
  }

  sleep(1);
}
