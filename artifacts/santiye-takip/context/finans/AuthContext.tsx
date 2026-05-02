import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";

import {
  apiLogin,
  apiMe,
  apiRegister,
  clearToken,
  getStoredToken,
  storeToken,
  type AuthUser,
} from "@/utils/finans/authApi";

interface AuthContextType {
  user: AuthUser | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  isLoggedIn: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const stored = await getStoredToken();
        if (stored) {
          const me = await apiMe(stored);
          if (me) {
            setToken(stored);
            setUser(me);
          } else {
            await clearToken();
          }
        }
      } finally {
        setIsLoading(false);
      }
    })();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const result = await apiLogin(email, password);
    await storeToken(result.token);
    setToken(result.token);
    setUser(result.user);
  }, []);

  const register = useCallback(
    async (name: string, email: string, password: string) => {
      const result = await apiRegister(name, email, password);
      await storeToken(result.token);
      setToken(result.token);
      setUser(result.user);
    },
    []
  );

  const logout = useCallback(async () => {
    await clearToken();
    setToken(null);
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        login,
        register,
        logout,
        isLoggedIn: !!user,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
