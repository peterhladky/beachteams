// Global test setup. Native modules that don't exist in Node must be mocked here.
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);
