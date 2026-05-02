import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { createContext, useContext, useEffect, useState } from "react";

const ENABLED_KEY = "@voice_assistant_enabled";

interface VoiceAssistantContextValue {
  enabled: boolean;
  setEnabled: (v: boolean) => void;
}

const VoiceAssistantContext = createContext<VoiceAssistantContextValue>({
  enabled: true,
  setEnabled: () => {},
});

export function VoiceAssistantProvider({ children }: { children: React.ReactNode }) {
  const [enabled, setEnabledState] = useState(true);

  useEffect(() => {
    AsyncStorage.getItem(ENABLED_KEY).then((val) => {
      if (val !== null) setEnabledState(val === "true");
    });
  }, []);

  const setEnabled = (v: boolean) => {
    setEnabledState(v);
    AsyncStorage.setItem(ENABLED_KEY, String(v));
  };

  return (
    <VoiceAssistantContext.Provider value={{ enabled, setEnabled }}>
      {children}
    </VoiceAssistantContext.Provider>
  );
}

export function useVoiceAssistant() {
  return useContext(VoiceAssistantContext);
}
