import http from 'k6/http';
import { check, fail, sleep } from 'k6';

// 压测配置
export let options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 0 },
  ],
};

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8080/api';
const LOGIN_EMAIL = __ENV.LOGIN_EMAIL || 'test@qq.com';
const LOGIN_PASSWORD = __ENV.LOGIN_PASSWORD || 'REDACTED_PASSWORD';

export function setup() { // 准备阶段，只执行一次
  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: LOGIN_EMAIL,
      password: LOGIN_PASSWORD,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: '20s',
    },
  );

  if (loginRes.status !== 200) {
    console.log(
      `Login failed! status=${loginRes.status}, error=${loginRes.error || 'none'}, error_code=${loginRes.error_code || 'none'}, body=${loginRes.body}`,
    );
    fail(`Setup failed: login request was not successful`);
  }

  const token = loginRes.json('token');
  if (!token) {
    console.log(`Login response missing token. body=${loginRes.body}`);
    fail('Setup failed: token missing in login response');
  }

  return { token };
}

export default function (data) {
  const authHeaders = {
    Authorization: `Bearer ${data.token}`,
    'Content-Type': 'application/json',
  };

  const res = http.get(`${BASE_URL}/goals`, {
    headers: authHeaders,
    timeout: '20s',
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'has body': (r) => r.body !== null,
  });

  if (res.status !== 200) {
    console.log(
      `Request failed! status=${res.status}, error=${res.error || 'none'}, error_code=${res.error_code || 'none'}, body=${res.body}`,
    );
  }

  sleep(1);
}
