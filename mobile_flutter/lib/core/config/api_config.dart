const configuredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);
const apiBaseUrl = configuredApiBaseUrl == ''
    ? 'https://mobile-test-z718.onrender.com'
    : configuredApiBaseUrl;
const useLocalApiFallbacks = bool.fromEnvironment(
  'USE_LOCAL_API_FALLBACKS',
  defaultValue: false,
);
const localApiFallbackBaseUrls = [
  'http://10.0.2.2:5000',
  'http://localhost:5000',
];
