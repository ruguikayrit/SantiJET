import { useCurrency } from "@/context/finans/CurrencyContext";

export function useFormatAmount(): (tryAmount: number) => string {
  return useCurrency().formatAmount;
}
