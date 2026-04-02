import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, REQUEST_TIMEOUT, jsonHeaders, logFailure, setupAuth } from './common.js';

export const options = {
  stages: [
    { duration: '30s', target: 2 },
    { duration: '1m', target: 10 },
    { duration: '30s', target: 0 },
  ],
};

export const setup = setupAuth;

export default function (data) {
  const res = http.get(`${BASE_URL}/account/export`, {
    headers: jsonHeaders(data.token),
    timeout: REQUEST_TIMEOUT,
  });

  check(res, {
    'account export status is 200': (r) => r.status === 200,
    'account export body exists': (r) => r.body && r.body.length > 0,
  });

  if (res.status !== 200) {
    logFailure('account export', res);
  }

  sleep(1);
}
