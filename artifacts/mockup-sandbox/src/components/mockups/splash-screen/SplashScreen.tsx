import { useEffect, useRef } from "react";

const NAVY_TOP = "#071226";
const NAVY_BOT = "#020611";
const WHITE = "#F5F7FA";
const BLUE = "#0066FF";
const BLUE_GLOW = "rgba(0,102,255,0.35)";

export function SplashScreen() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const W = 390;
    const H = 844;
    canvas.width = W;
    canvas.height = H;

    const LINE_COUNT = 22;

    type Line = {
      x: number;
      segments: { y: number; len: number; alpha: number }[];
      speed: number;
      offset: number;
    };

    const lines: Line[] = Array.from({ length: LINE_COUNT }, () => ({
      x: Math.random() * W,
      segments: Array.from({ length: 3 + Math.floor(Math.random() * 4) }, () => ({
        y: Math.random() * H,
        len: 12 + Math.random() * 60,
        alpha: 0.012 + Math.random() * 0.022,
      })),
      speed: 0.15 + Math.random() * 0.25,
      offset: Math.random() * H,
    }));

    let raf: number;
    function draw() {
      ctx!.clearRect(0, 0, W, H);

      for (const line of lines) {
        for (const seg of line.segments) {
          seg.y += line.speed;
          if (seg.y > H + seg.len) seg.y = -seg.len;

          const grad = ctx!.createLinearGradient(line.x, seg.y, line.x, seg.y + seg.len);
          grad.addColorStop(0, `rgba(0,102,255,0)`);
          grad.addColorStop(0.4, `rgba(0,102,255,${seg.alpha})`);
          grad.addColorStop(0.7, `rgba(100,160,255,${seg.alpha * 0.7})`);
          grad.addColorStop(1, `rgba(0,102,255,0)`);
          ctx!.strokeStyle = grad;
          ctx!.lineWidth = 0.6;
          ctx!.beginPath();
          ctx!.moveTo(line.x, seg.y);
          ctx!.lineTo(line.x, seg.y + seg.len);
          ctx!.stroke();
        }
      }
      raf = requestAnimationFrame(draw);
    }
    draw();
    return () => cancelAnimationFrame(raf);
  }, []);

  return (
    <div
      style={{
        width: 390,
        height: 844,
        position: "relative",
        overflow: "hidden",
        background: `linear-gradient(180deg, ${NAVY_TOP} 0%, ${NAVY_BOT} 100%)`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "'Inter', 'SF Pro Display', system-ui, sans-serif",
      }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap');

        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(12px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes glowPulse {
          0%, 100% { opacity: 0.55; transform: translateX(-50%) scale(1); }
          50%       { opacity: 0.75; transform: translateX(-50%) scale(1.06); }
        }
        @keyframes iconFadeIn {
          from { opacity: 0; transform: scale(0.93) translateY(8px); }
          to   { opacity: 1; transform: scale(1) translateY(0); }
        }
        .splash-logo { animation: iconFadeIn 0.9s cubic-bezier(0.16,1,0.3,1) 0.2s both; }
        .splash-wordmark { animation: fadeIn 0.8s cubic-bezier(0.16,1,0.3,1) 0.7s both; }
        .splash-tagline { animation: fadeIn 0.7s cubic-bezier(0.16,1,0.3,1) 1.0s both; }
      `}</style>

      {/* Ambient data-flow lines canvas */}
      <canvas
        ref={canvasRef}
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          opacity: 0.9,
          pointerEvents: "none",
        }}
      />

      {/* Wide ambient halo behind logo — very diffuse */}
      <div
        style={{
          position: "absolute",
          top: "26%",
          left: "50%",
          transform: "translateX(-50%)",
          width: 340,
          height: 340,
          background: `radial-gradient(ellipse at center, rgba(0,80,200,0.08) 0%, transparent 72%)`,
          borderRadius: "50%",
          filter: "blur(24px)",
          pointerEvents: "none",
        }}
      />

      {/* Blue glow bloom beneath icon — pulsing */}
      <div
        style={{
          position: "absolute",
          top: "44%",
          left: "50%",
          width: 180,
          height: 80,
          background: `radial-gradient(ellipse at center, ${BLUE_GLOW} 0%, transparent 70%)`,
          filter: "blur(18px)",
          animation: "glowPulse 3.8s ease-in-out infinite",
          pointerEvents: "none",
        }}
      />

      {/* Logo group */}
      <div
        style={{
          position: "relative",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 32,
          zIndex: 10,
        }}
      >
        {/* S-Bolt SVG icon */}
        <div className="splash-logo" style={{ position: "relative" }}>
          <svg
            width={108}
            height={156}
            viewBox="0 0 280 400"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            style={{ display: "block" }}
          >
            <defs>
              {/* Blue glow filter */}
              <filter id="blueGlowF" x="-60%" y="-60%" width="220%" height="220%">
                <feGaussianBlur in="SourceGraphic" stdDeviation="14" result="blurred" />
                <feMerge>
                  <feMergeNode in="blurred" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              {/* Soft white glow filter */}
              <filter id="whiteGlowF" x="-40%" y="-40%" width="180%" height="180%">
                <feGaussianBlur in="SourceGraphic" stdDeviation="6" result="blurred" />
                <feMerge>
                  <feMergeNode in="blurred" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              {/* Clip path for white shape */}
              <clipPath id="upperClip">
                <polygon points="185,8 258,44 162,218 32,218 90,124" />
              </clipPath>
            </defs>

            {/* White upper blade */}
            <polygon
              points="185,8 258,44 162,218 32,218 90,124"
              fill={WHITE}
              filter="url(#whiteGlowF)"
            />

            {/* Blue lower blade */}
            <polygon
              points="118,192 258,192 258,218 205,308 102,398 38,372"
              fill={BLUE}
              filter="url(#blueGlowF)"
            />

            {/* Subtle inner highlight on white blade — depth */}
            <polygon
              points="185,8 258,44 230,100 180,60"
              fill="rgba(255,255,255,0.18)"
            />
          </svg>
        </div>

        {/* Wordmark */}
        <div
          className="splash-wordmark"
          style={{
            display: "flex",
            alignItems: "baseline",
            letterSpacing: "0.22em",
            userSelect: "none",
          }}
        >
          <span
            style={{
              fontSize: 30,
              fontWeight: 900,
              color: WHITE,
              textTransform: "uppercase",
              lineHeight: 1,
              fontFamily: "'Inter', system-ui, sans-serif",
            }}
          >
            Şanti
          </span>
          <span
            style={{
              fontSize: 30,
              fontWeight: 900,
              color: BLUE,
              textTransform: "uppercase",
              lineHeight: 1,
              fontFamily: "'Inter', system-ui, sans-serif",
              textShadow: `0 0 18px rgba(0,102,255,0.55), 0 0 40px rgba(0,102,255,0.25)`,
              letterSpacing: "0.22em",
            }}
          >
            JET
          </span>
        </div>

        {/* Fine separator line only — no text */}
        <div
          className="splash-tagline"
          style={{
            display: "flex",
            alignItems: "center",
            gap: 0,
            marginTop: -8,
          }}
        >
          <div
            style={{
              width: 120,
              height: 0.5,
              background: `linear-gradient(to right, transparent, rgba(0,102,255,0.22), transparent)`,
            }}
          />
        </div>
      </div>

      {/* Bottom fade vignette */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          background: `linear-gradient(to top, ${NAVY_BOT} 0%, transparent 100%)`,
          pointerEvents: "none",
        }}
      />

      {/* Top fade vignette */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          background: `linear-gradient(to bottom, ${NAVY_TOP} 0%, transparent 100%)`,
          pointerEvents: "none",
        }}
      />
    </div>
  );
}
