export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("tr-TR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount) + " ₺";
}

export function formatDate(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString("tr-TR", {
    day: "2-digit",
    month: "short",
  });
}

export function formatMonth(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString("tr-TR", {
    month: "long",
    year: "numeric",
  });
}
