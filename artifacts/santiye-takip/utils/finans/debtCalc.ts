export function todayYM(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

export function ymToNum(ym: string): number {
  const [y, m] = ym.split("-").map(Number);
  return y * 12 + (m - 1);
}

export function numToYM(n: number): string {
  const y = Math.floor(n / 12);
  const m = (n % 12) + 1;
  return `${y}-${String(m).padStart(2, "0")}`;
}

export function installmentRemainingAtYM(
  amount: number,
  date: string,
  totalInstallments: number,
  ym: string
): number {
  const startDate = new Date(date);
  const startYM = `${startDate.getFullYear()}-${String(startDate.getMonth() + 1).padStart(2, "0")}`;
  if (ym < startYM) return 0;
  const N = Math.max(1, totalInstallments);
  const monthly = amount / N;
  const elapsed = ymToNum(ym) - ymToNum(startYM) + 1;
  const paid = Math.min(elapsed, N);
  return Math.max(0, amount - paid * monthly);
}

export function regularRemainingAtYM(
  amount: number,
  payments: { date: string; amount: number }[],
  ym: string
): number {
  const [y, m] = ym.split("-").map(Number);
  const endOfMonth = new Date(y, m, 0, 23, 59, 59, 999);
  const paidBefore = payments
    .filter((p) => new Date(p.date) <= endOfMonth)
    .reduce((s, p) => s + p.amount, 0);
  return Math.max(0, amount - paidBefore);
}
