import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";

const PIN_KEY = "@budget_pin";

interface PinContextValue {
  pin: string | null;
  isLocked: boolean;
  loading: boolean;
  unlock: (entered: string) => boolean;
  setPin: (newPin: string) => Promise<void>;
  removePin: () => Promise<void>;
  lockApp: () => void;
}

const PinContext = createContext<PinContextValue | null>(null);

export function PinProvider({ children }: { children: React.ReactNode }) {
  const [pin, setStoredPin] = useState<string | null>(null);
  const [isLocked, setIsLocked] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    AsyncStorage.getItem(PIN_KEY).then((stored) => {
      if (stored) {
        setStoredPin(stored);
        setIsLocked(true);
      }
      setLoading(false);
    });
  }, []);

  const unlock = useCallback(
    (entered: string) => {
      if (entered === pin) {
        setIsLocked(false);
        return true;
      }
      return false;
    },
    [pin]
  );

  const setPin = useCallback(async (newPin: string) => {
    await AsyncStorage.setItem(PIN_KEY, newPin);
    setStoredPin(newPin);
  }, []);

  const removePin = useCallback(async () => {
    await AsyncStorage.removeItem(PIN_KEY);
    setStoredPin(null);
    setIsLocked(false);
  }, []);

  const lockApp = useCallback(() => {
    if (pin) setIsLocked(true);
  }, [pin]);

  return (
    <PinContext.Provider
      value={{ pin, isLocked, loading, unlock, setPin, removePin, lockApp }}
    >
      {children}
    </PinContext.Provider>
  );
}

export function usePin() {
  const ctx = useContext(PinContext);
  if (!ctx) throw new Error("usePin must be used inside PinProvider");
  return ctx;
}
