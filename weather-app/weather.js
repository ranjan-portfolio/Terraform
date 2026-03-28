import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,          // 50 concurrent users
  duration: '30s',  // Run for 30 seconds
};

export default function () {
  // REPLACE THIS with your actual API Gateway Invoke URL
  const apiUrl = 'https://ws04gh2cvf.execute-api.eu-west-2.amazonaws.com/prod/weather-api-test'; 
  
  const res = http.get(apiUrl);

  check(res, {
    'is status 200': (r) => r.status === 200,
  });

  sleep(1);
}

