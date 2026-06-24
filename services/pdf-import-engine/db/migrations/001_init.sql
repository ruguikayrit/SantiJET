-- Şantijet PDF Import Engine — initial schema

CREATE TABLE IF NOT EXISTS import_jobs (
    id              BIGSERIAL PRIMARY KEY,
    kurum           TEXT NOT NULL,
    yil             INTEGER NOT NULL,
    kaynak_dosya    TEXT NOT NULL,
    format_id       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending',
    expected_count  INTEGER,
    imported_count  INTEGER DEFAULT 0,
    failed_count    INTEGER DEFAULT 0,
    started_at      TIMESTAMPTZ,
    finished_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS poz_kayitlari (
    id              BIGSERIAL PRIMARY KEY,
    job_id          BIGINT REFERENCES import_jobs(id) ON DELETE SET NULL,
    kurum           TEXT NOT NULL,
    yil             INTEGER NOT NULL,
    kaynak_dosya    TEXT NOT NULL,
    kaynak_sayfa    INTEGER,
    poz_no          TEXT NOT NULL,
    poz_adi         TEXT NOT NULL,
    birim           TEXT NOT NULL,
    yapim_sarti     TEXT DEFAULT '',
    analiz          TEXT DEFAULT '',
    birim_fiyat     NUMERIC(18, 2),
    para_birimi     TEXT NOT NULL DEFAULT 'TRY',
    kategori        TEXT DEFAULT '',
    alt_kategori    TEXT DEFAULT '',
    payload         JSONB NOT NULL DEFAULT '{}',
    olusturma_tarihi TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (kurum, yil, poz_no)
);

CREATE TABLE IF NOT EXISTS poz_hatalari (
    id              BIGSERIAL PRIMARY KEY,
    job_id          BIGINT REFERENCES import_jobs(id) ON DELETE CASCADE,
    kaynak_dosya    TEXT,
    kaynak_sayfa    INTEGER,
    poz_no          TEXT,
    hata_kodu       TEXT NOT NULL,
    hata_mesaji     TEXT NOT NULL,
    ham_veri        JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS poz_dogrulama_kuyrugu (
    id              BIGSERIAL PRIMARY KEY,
    job_id          BIGINT REFERENCES import_jobs(id) ON DELETE CASCADE,
    poz_no          TEXT NOT NULL,
    sebep           TEXT NOT NULL,
    kayit           JSONB NOT NULL,
    durum           TEXT NOT NULL DEFAULT 'bekliyor',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_poz_kayitlari_kurum_yil ON poz_kayitlari (kurum, yil);
CREATE INDEX IF NOT EXISTS idx_poz_kayitlari_poz_no ON poz_kayitlari (poz_no);
CREATE INDEX IF NOT EXISTS idx_poz_hatalari_job ON poz_hatalari (job_id);
