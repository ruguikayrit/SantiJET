# Güvenlik Politikası — ŞantiJET DEMİR

## Kapsam

Bu belge, ŞantiJET DEMİR uygulaması ve kaynak kod deposu için temel güvenlik
kurallarını tanımlar.

## Kod koruması

- Depodaki kaynak kod **telif hakkı ile korunmaktadır** (`LICENSE` dosyasına bakın).
- Public repo kullanıyorsanız kod herkes tarafından görülebilir. Kodu gizlemek
  için GitHub repo'yu **Private** yapın.
- API anahtarları, şifreler, `.env` dosyaları ve müşteri veritabanı dump'ları
  **asla** repoya commit edilmemelidir.

## Uygulama kilidi (PIN)

- Uygulama açılışında **4 haneli PIN** istenir.
- **Varsayılan PIN:** `220626` (22.06.26) — ilk girişten sonra **Ayarlar → Uygulama Kilidi**
  bölümünden mutlaka değiştirin.
- PIN, cihazda hash olarak saklanır; düz metin depolanmaz.
- 5 hatalı denemeden sonra 30 saniye geçici kilit uygulanır.
- Sayfa yenilendiğinde veya uygulama kilitlendiğinde PIN tekrar istenir.

> **Önemli:** Web/PWA uygulamalarında istemci tarafı PIN, rastgele ziyaretçilere
> karşı **pratik bir engeldir**; kaynak kodu inceleyen bir geliştiriciye karşı
> tam güvenlik sağlamaz. Asıl koruma için private repo + backend kimlik doğrulama
> kullanın.

## Veri güvenliği

| Veri türü | Şu anki durum | Öneri |
|-----------|---------------|-------|
| Sipariş / keşif / sayım | Mock (örnek) veri | Gerçek veri için sunucu + auth |
| Ayarlar | Cihazda Hive (yerel) | Hassas ayarları sunucuda tutun |
| Kullanıcı hesapları | Henüz yok | Firebase Auth / Supabase Auth |

Gerçek müşteri verisi eklendiğinde:

1. Tüm API iletişimi **HTTPS** üzerinden olmalı
2. Her kullanıcı yalnızca kendi verisini görmeli (sunucu tarafı kurallar)
3. Veritabanı yedekleri şifreli saklanmalı

## Repoda bulunmaması gerekenler

```
.env
*.pem
*.p12
google-services.json (production)
GoogleService-Info.plist (production)
firebase-adminsdk-*.json
API keys / tokens
Gerçek müşteri listeleri
```

`.gitignore` bu dosyaları kapsamalıdır.

## Güvenlik açığı bildirimi

Bir güvenlik açığı tespit ederseniz:

1. Konuyu **public issue olarak açmayın**
2. Depo sahibine **özel kanaldan** bildirin (GitHub Security Advisories veya e-posta)
3. Düzeltme yayınlanana kadar detayları paylaşmayın

## Sorumlu kullanım checklist

- [ ] Varsayılan PIN değiştirildi
- [ ] Repo private yapıldı (kod gizliliği için)
- [ ] Production API anahtarları repoda yok
- [ ] GitHub Actions secrets kullanılıyor
- [ ] Gerçek veri için backend auth planlandı

## Sürüm

Son güncelleme: 2025 — v1.0
