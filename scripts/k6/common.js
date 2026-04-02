import http from 'k6/http';
import { check, fail } from 'k6';

export const BASE_URL = (__ENV.BASE_URL || 'http://127.0.0.1:8080/api').replace(/\/$/, '');
export const LOGIN_EMAIL = __ENV.LOGIN_EMAIL || 'test@qq.com';
export const LOGIN_PASSWORD = __ENV.LOGIN_PASSWORD || 'REDACTED_PASSWORD';
export const REQUEST_TIMEOUT = __ENV.REQUEST_TIMEOUT || '20s';

export function jsonHeaders(token) {
  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

export function logFailure(label, res) {
  console.log(
    `${label} failed: status=${res.status}, error=${res.error || 'none'}, error_code=${res.error_code || 'none'}, body=${res.body}`,
  );
}

export function login() {
  const res = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: LOGIN_EMAIL,
      password: LOGIN_PASSWORD,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: REQUEST_TIMEOUT,
    },
  );

  if (res.status !== 200) {
    logFailure('login', res);
    fail('setup failed: login was not successful');
  }

  const token = res.json('token');
  if (!token) {
    console.log(`login missing token: body=${res.body}`);
    fail('setup failed: token missing in login response');
  }
  return token;
}

export function setupAuth() {
  return { token: login() };
}

export function getGoals(token) {
  const res = http.get(`${BASE_URL}/goals`, {
    headers: jsonHeaders(token),
    timeout: REQUEST_TIMEOUT,
  });
  check(res, { 'get goals status is 200': (r) => r.status === 200 });
  if (res.status !== 200) {
    logFailure('get goals', res);
    fail('setup failed: could not load goals');
  }
  return res.json();
}

export function requireGoalWithTasks(token) {
  const goals = getGoals(token);
  const goal = goals.find(
    (item) =>
      Array.isArray(item.taskPlan) &&
      item.taskPlan.length > 0 &&
      Array.isArray(item.taskPlan[0]) &&
      item.taskPlan[0].length > 0 &&
      item.createdAt,
  );
  if (!goal) {
    fail('setup failed: no goal with non-empty taskPlan found');
  }
  return goal;
}

export function formatDate(value) {
  return new Date(value).toISOString().slice(0, 10);
}

export function plusDays(dateText, days) {
  const date = new Date(`${dateText}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

export function randomInt(maxExclusive) {
  return Math.floor(Math.random() * maxExclusive);
}

export function buildTaskActionGoal(goal) {
  const sourceDate = formatDate(goal.createdAt);
  const firstDayTasks = goal.taskPlan[0];
  return {
    goalId: goal.id,
    sourceDate,
    taskIndex: randomInt(firstDayTasks.length),
  };
}

export function getHabits(token) {
  const res = http.get(`${BASE_URL}/habits`, {
    headers: jsonHeaders(token),
    timeout: REQUEST_TIMEOUT,
  });
  check(res, { 'get habits status is 200': (r) => r.status === 200 });
  if (res.status !== 200) {
    logFailure('get habits', res);
    fail('setup failed: could not load habits');
  }
  return res.json();
}

export function requireHabit(token) {
  const habits = getHabits(token);
  if (!Array.isArray(habits) || habits.length === 0) {
    fail('setup failed: no habits found');
  }
  return habits[0];
}

export function buildDailyReviewPayload(vu, iter) {
  return {
    tomorrowTopPriority: `k6 priority vu=${vu} iter=${iter}`,
    items: [
      { dimension: 'WORK_STUDY', status: 'GOOD', comment: `work ${vu}-${iter}` },
      { dimension: 'HEALTH', status: 'NORMAL', comment: `health ${vu}-${iter}` },
      { dimension: 'RELATIONSHIP', status: 'GOOD', comment: `relationship ${vu}-${iter}` },
      { dimension: 'HOBBY', status: 'BAD', comment: `hobby ${vu}-${iter}` },
    ],
  };
}
