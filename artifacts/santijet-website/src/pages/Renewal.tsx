import { useEffect, useState } from "react";

const BASE_URL = import.meta.env.BASE_URL.replace(/\/$/, "");
const STORAGE_KEY = "santijet-site-lang";

type Lang = "tr" | "en";

const COPY = {
  tr: {
    title: "ŞantiJET — Yenileniyoruz",
    description:
      "Yenileniyoruz... ŞantiJET yeni yüzüyle hazırlanıyor... Kısa süre sonra buradayız...",
    heading: "Yenileniyoruz...",
    line1: "ŞantiJET yeni yüzüyle hazırlanıyor...",
    line2: "Kısa süre sonra buradayız...",
    langLabel: "Dil",
  },
  en: {
    title: "ŞantiJET — We're renewing",
    description:
      "We're renewing... ŞantiJET is getting a new look... We'll be here shortly...",
    heading: "We're renewing...",
    line1: "ŞantiJET is getting a new look...",
    line2: "We'll be here shortly...",
    langLabel: "Language",
  },
} as const;

function storedLang(): Lang {
  try {
    return localStorage.getItem(STORAGE_KEY) === "en" ? "en" : "tr";
  } catch {
    return "tr";
  }
}

export default function Renewal() {
  const [lang, setLang] = useState<Lang>(storedLang);
  const copy = COPY[lang];

  useEffect(() => {
    document.documentElement.lang = lang;
    document.title = copy.title;
    document.querySelector('meta[name="description"]')?.setAttribute("content", copy.description);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch {
      /* depolama kapalıysa seçim yalnızca bu görünümde kalır */
    }
  }, [lang, copy]);

  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden bg-background px-6 text-center text-foreground">
      <div
        className="fixed right-[22px] top-[22px] z-20 flex rounded-full border border-white/10 p-[3px]"
        role="group"
        aria-label={copy.langLabel}
      >
        {(["tr", "en"] as const).map((code) => {
          const selected = lang === code;
          return (
            <button
              key={code}
              type="button"
              aria-pressed={selected}
              onClick={() => setLang(code)}
              className={`cursor-pointer rounded-full px-2.5 py-1.5 text-[0.78rem] font-bold tracking-[0.04em] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-[3px] focus-visible:outline-primary ${
                selected ? "bg-foreground text-background" : "text-muted-foreground"
              }`}
            >
              {code.toUpperCase()}
            </button>
          );
        })}
      </div>
      <div className="pointer-events-none absolute left-1/2 top-1/2 h-[560px] w-[560px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/20 blur-[120px]" />
      <div className="relative flex flex-col items-center">
        <img
          src={`${BASE_URL}/brand/santijet-bolt-nobg.png`}
          alt=""
          className="mb-[-0.35rem] h-[10.5rem] w-[10.5rem] object-contain"
        />
        <img
          src={`${BASE_URL}/brand/santijet-wordmark-plain-nobg.png`}
          alt="ŞantiJET"
          className="h-11 w-auto object-contain"
        />
        <div className="mt-12 flex max-w-md flex-col gap-3">
          <h1 className="text-3xl font-semibold tracking-tight md:text-4xl">{copy.heading}</h1>
          <div className="flex flex-col gap-[2.75px]">
            <p className="text-base leading-relaxed text-muted-foreground">{copy.line1}</p>
            <p className="text-base leading-relaxed text-muted-foreground">{copy.line2}</p>
          </div>
        </div>
      </div>
    </main>
  );
}
