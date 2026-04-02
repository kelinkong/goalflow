import http from 'k6/http';
import { check, sleep } from 'k6';
import {
  BASE_URL,
  REQUEST_TIMEOUT,
  buildTaskActionGoal,
  jsonHeaders,
  logFailure,
  plusDays,
  requireGoalWithTasks,
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
  const goal = requireGoalWithTasks(auth.token);
  return { ...auth, taskTarget: buildTaskActionGoal(goal) };
}

export default function (data) {
  const headers = jsonHeaders(data.token);
  const action = __ITER % 2 === 0 ? 'checkin' : 'defer';
  const payload =
    action === 'checkin'
      ? {
          sourceDate: data.taskTarget.sourceDate,
          taskIndex: data.taskTarget.taskIndex,
          done: true,
          isMakeup: false,
        }
      : {
          sourceDate: data.taskTarget.sourceDate,
          taskIndex: data.taskTarget.taskIndex,
          targetDate: plusDays(data.taskTarget.sourceDate, 1),
        };

  const res = http.post(
    `${BASE_URL}/goals/${data.taskTarget.goalId}/${action}`,
    JSON.stringify(payload),
    {
      headers,
      timeout: REQUEST_TIMEOUT,
    },
  );

  check(res, {
    'task action status is 200': (r) => r.status === 200,
  });

  if (res.status !== 200) {
    logFailure(`task ${action}`, res);
  }

  sleep(1);
}
