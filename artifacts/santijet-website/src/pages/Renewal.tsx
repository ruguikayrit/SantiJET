const BASE_URL = import.meta.env.BASE_URL.replace(/\/$/, "");

export default function Renewal() {
  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden bg-background px-6 text-center text-foreground">
      <div className="pointer-events-none absolute left-1/2 top-1/2 h-[560px] w-[560px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/20 blur-[120px]" />
      <div className="relative flex flex-col items-center">
        <img
          src={`${BASE_URL}/brand/santijet-bolt-nobg.png`}
          alt=""
          className="mb-2 h-[10.5rem] w-[10.5rem] object-contain"
        />
        <img
          src={`${BASE_URL}/brand/santijet-wordmark-plain-nobg.png`}
          alt="ŞantiJET"
          className="h-11 w-auto object-contain"
        />
        <div className="mt-12 flex max-w-md flex-col gap-3">
          <h1 className="text-3xl font-semibold tracking-tight md:text-4xl">Yenileniyoruz...</h1>
          <p className="text-base leading-relaxed text-muted-foreground">ŞantiJET yeni yüzüyle hazırlanıyor...</p>
          <p className="text-base leading-relaxed text-muted-foreground">Kısa süre sonra buradayız...</p>
        </div>
      </div>
    </main>
  );
}
