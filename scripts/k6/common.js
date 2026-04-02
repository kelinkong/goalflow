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

function normalizeGoalList(payload) {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (payload && Array.isArray(payload.content)) {
    return payload.content;
  }

  return [];
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
  return normalizeGoalList(res.json());
}

export function getGoalDetail(token, goalId) {
  const res = http.get(`${BASE_URL}/goals/${goalId}`, {
    headers: jsonHeaders(token),
    timeout: REQUEST_TIMEOUT,
  });
  if (res.status !== 200) {
    logFailure(`get goal detail ${goalId}`, res);
    fail(`setup failed: could not load goal detail for ${goalId}`);
  }
  return res.json();
}

export function requireGoalWithTasks(token) {
  const goals = getGoals(token);
  if (!Array.isArray(goals) || goals.length === 0) {
    fail('setup failed: no goals found');
  }

  // 尝试找到一个看起来有任务的目标（即使列表没返回 taskPlan）
  for (const item of goals) {
    const detail = getGoalDetail(token, item.id);
    if (
      Array.isArray(detail.taskPlan) &&
      detail.taskPlan.length > 0 &&
      Array.isArray(detail.taskPlan[0]) &&
      detail.taskPlan[0].length > 0
    ) {
      return detail;
    }
  }

  fail('setup failed: no goal with non-empty taskPlan found after checking details');
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
