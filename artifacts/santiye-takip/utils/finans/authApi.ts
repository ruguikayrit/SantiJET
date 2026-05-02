import AsyncStorage from "@react-native-async-storage/async-storage";

export const TOKEN_KEY = "@auth_token";

const API_BASE = process.env.EXPO_PUBLIC_DOMAIN
  ? `https://${process.env.EXPO_PUBLIC_DOMAIN}:8080/api`
  : "http://localhost:8080/api";

export interface AuthUser {
  id: number;
  name: string;
  email: string;
}

export interface AuthResult {
  token: string;
  user: AuthUser;
}

async function post(path: string, body: object): Promise<any> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.error ?? `Sunucu hatası (${res.status})`);
  return json;
}

export async function apiRegister(
  name: string,
  email: string,
  password: string
): Promise<AuthResult> {
  return post("/auth/register", { name, email, password });
}

export async function apiLogin(
  email: string,
  password: string
): Promise<AuthResult> {
  return post("/auth/login", { email, password });
}

export async function apiMe(token: string): Promise<AuthUser | null> {
  try {
    const res = await fetch(`${API_BASE}/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) return null;
    const json = await res.json();
    return json.user ?? null;
  } catch {
    return null;
  }
}

export async function getStoredToken(): Promise<string | null> {
  return AsyncStorage.getItem(TOKEN_KEY);
}

export async function storeToken(token: string): Promise<void> {
  await AsyncStorage.setItem(TOKEN_KEY, token);
}

export async function clearToken(): Promise<void> {
  await AsyncStorage.removeItem(TOKEN_KEY);
}
