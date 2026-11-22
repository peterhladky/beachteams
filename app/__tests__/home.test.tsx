import { render, screen } from '@testing-library/react-native';

import HomeScreen from '../src/app/index';

// Smoke test: proves the test toolchain works. Real acceptance tests live in
// __tests__/acceptance/req-<N>/ and are written by the Test Designer agent.
describe('HomeScreen', () => {
  it('shows the welcome header', async () => {
    await render(<HomeScreen />);
    expect(screen.getByRole('header', { name: 'Welcome' })).toBeTruthy();
  });
});
