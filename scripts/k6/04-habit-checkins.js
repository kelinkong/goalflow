import http from 'k6/http';
import { check, sleep } from 'k6';
import {
  BASE_URL,
  REQUEST_TIMEOUT,
  formatDate,
  jsonHeaders,
  logFailure,
  requireHabit,
  setupAuth,
} from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 30 },
    { duration: '30s', target: 0 },
  ],
};

export function setup() {
  const auth = setupAuth();
  const habit = requireHabit(auth.token);
  return { ...auth, habitId: habit.id };
}

export default function (data) {
  const today = formatDate(new Date().toISOString());
  const res = http.put(
    `${BASE_URL}/habits/${data.habitId}/checkins/${today}`,
    JSON.stringify({ isDone: __ITER % 3 !== 0 }),
    {
      headers: jsonHeaders(data.token),
      timeout: REQUEST_TIMEOUT,
    },
  );

  check(res, {
    'habit checkin status is 200': (r) => r.status === 200,
  });

  if (res.status !== 200) {
    logFailure('habit checkin', res);
  }

  sleep(1);
}
