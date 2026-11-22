import { getSupabase } from '../../src/lib/supabase';

describe('getSupabase', () => {
  const original = { ...process.env };
  afterEach(() => {
    process.env = { ...original };
  });

  it('fails with a clear message when env is missing', () => {
    delete process.env.EXPO_PUBLIC_SUPABASE_URL;
    delete process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
    expect(() => getSupabase()).toThrow(/not configured/i);
  });
});
