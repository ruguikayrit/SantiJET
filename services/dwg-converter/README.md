# ŞantiJET DWG Converter

DWG dosyalarını LibreDWG (`dwg2dxf`) ile okuyup demir metraj segmentlerini JSON olarak döner.

## Çalıştırma

```bash
cd services/dwg-converter
docker build -t santijet-dwg-converter .
docker run --rm -p 8080:8080 santijet-dwg-converter
```

## API

- `GET /health`
- `POST /convert` — multipart `file` alanı ile DWG yükleyin

Yanıt:

```json
{
  "segments": [
    { "layerName": "DONATI_12", "length": 10.5 }
  ]
}
```

Flutter mobil/native için build sırasında:

```bash
--dart-define=DWG_CONVERTER_URL=https://your-converter.example.com
```

Web sürümünde tarayıcı içi LibreDWG WASM kullanılır; bu servis zorunlu değildir.
