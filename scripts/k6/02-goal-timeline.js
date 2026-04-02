import http from 'k6/http';
import { check, sleep } from 'k6';
import {
  BASE_URL,
  REQUEST_TIMEOUT,
  jsonHeaders,
  logFailure,
  requireGoalWithTasks,
  setupAuth,
} from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 0 },
  ],
};

export function setup() {
  const auth = setupAuth();
  const goal = requireGoalWithTasks(auth.token);
  return { ...auth, goalId: goal.id };
}

export default function (data) {
  const res = http.get(`${BASE_URL}/goals/${data.goalId}/timeline`, {
    headers: jsonHeaders(data.token),
    timeout: REQUEST_TIMEOUT,
  });

  check(res, {
    'timeline status is 200': (r) => r.status === 200,
    'timeline is array': (r) => Array.isArray(r.json()),
  });

  if (res.status !== 200) {
    logFailure('goal timeline', res);
  }

  sleep(1);
}
