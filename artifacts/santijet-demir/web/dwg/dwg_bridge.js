window.__SANTIJET_DWG_MODULE__ = 'loading';

function cleanMText(raw) {
  if (!raw) return '';
  return String(raw)
    .replace(/\\P/gi, '\n')
    .replace(/\\[A-Za-z0-9.;]+/g, '')
    .replace(/[{}]/g, '')
    .trim();
}

(async () => {
  try {
    const { Dwg_File_Type, LibreDwg } = await import('./libredwg-web.js');
    const wasmUrl = new URL('./wasm/', import.meta.url).href;
    const libredwg = await LibreDwg.create(wasmUrl);

    window.santijetExtractDwgTexts = async (bytesArray) => {
      const bytes = bytesArray instanceof Uint8Array
        ? bytesArray
        : new Uint8Array(bytesArray);

      const dwg = libredwg.dwg_read_data(bytes, Dwg_File_Type.DWG);
      if (!dwg) {
        throw new Error('DWG dosyası okunamadı. Dosya bozuk veya desteklenmeyen sürüm olabilir.');
      }

      try {
        const db = libredwg.convert(dwg);
        const texts = [];

        for (const entity of db.entities ?? []) {
          if (entity.type === 'TEXT') {
            const text = String(entity.text ?? '').trim();
            if (text) texts.push(text);
            continue;
          }

          if (entity.type === 'MTEXT') {
            const text = cleanMText(entity.text);
            if (text) {
              for (const line of text.split('\n')) {
                const trimmed = line.trim();
                if (trimmed) texts.push(trimmed);
              }
            }
          }
        }

        return texts;
      } finally {
        libredwg.dwg_free(dwg);
      }
    };

    window.__SANTIJET_DWG_MODULE__ = 'ready';
  } catch (error) {
    console.error('ŞantiJET DWG modülü yüklenemedi:', error);
    window.__SANTIJET_DWG_MODULE__ = 'error';
    window.__SANTIJET_DWG_MODULE_ERROR__ = String(error);
  }
})();
