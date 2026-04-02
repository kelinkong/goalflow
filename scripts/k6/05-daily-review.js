import http from 'k6/http';
import { check, sleep } from 'k6';
import {
  BASE_URL,
  REQUEST_TIMEOUT,
  buildDailyReviewPayload,
  formatDate,
  jsonHeaders,
  logFailure,
  setupAuth,
} from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 3 },
    { duration: '1m', target: 15 },
    { duration: '30s', target: 0 },
  ],
};

export const setup = setupAuth;

export default function (data) {
  const today = formatDate(new Date().toISOString());
  const res = http.put(
    `${BASE_URL}/daily-reviews/${today}`,
    JSON.stringify(buildDailyReviewPayload(__VU, __ITER)),
    {
      headers: jsonHeaders(data.token),
      timeout: REQUEST_TIMEOUT,
    },
  );

  check(res, {
    'daily review status is 200': (r) => r.status === 200,
  });

  if (res.status !== 200) {
    logFailure('daily review upsert', res);
  }

  sleep(1);
}
