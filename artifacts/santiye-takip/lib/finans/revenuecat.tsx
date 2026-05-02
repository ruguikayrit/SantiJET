import React, { createContext, useContext } from "react";

export const REVENUECAT_ENTITLEMENT_IDENTIFIER = "premium";

export function initializeRevenueCat() {
  // No-op stub: native react-native-purchases is not bundled in ŞantiJET.
  // KasaFON's premium gating is disabled inside the embedded /finans section.
}

type SubscriptionContextValue = {
  customerInfo: { entitlements: { active: Record<string, any> }; originalAppUserId: string } | null;
  offerings: null;
  isSupported: boolean;
  isSubscribed: boolean;
  isLoading: boolean;
  purchase: (pkg: any) => Promise<any>;
  restore: () => Promise<any>;
  isPurchasing: boolean;
  isRestoring: boolean;
  purchaseError: null;
};

const noopValue: SubscriptionContextValue = {
  customerInfo: null,
  offerings: null,
  isSupported: false,
  isSubscribed: false,
  isLoading: false,
  purchase: async () => null,
  restore: async () => null,
  isPurchasing: false,
  isRestoring: false,
  purchaseError: null,
};

const Context = createContext<SubscriptionContextValue>(noopValue);

export function SubscriptionProvider({ children }: { children: React.ReactNode }) {
  return <Context.Provider value={noopValue}>{children}</Context.Provider>;
}

export function useSubscription() {
  return useContext(Context);
}
