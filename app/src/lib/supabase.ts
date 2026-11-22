import 'react-native-url-polyfill/auto';

import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | undefined;

/**
 * The ONE access point to Supabase. Components and screens must call this (or a service
 * built on it) instead of creating their own client.
 * Only the public anon key is used here. Security comes from Row Level Security.
 * The service_role key must never be used in this app (see docs/HARD-RULES.md).
 */
export function getSupabase(): SupabaseClient {
  if (client) return client;

  const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error('Supabase is not configured. Copy app/.env.example to app/.env and fill it in.');
  }

  client = createClient(url, anonKey, {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  });
  return client;
}
