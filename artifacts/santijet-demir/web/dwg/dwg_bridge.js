window.__SANTIJET_DWG_MODULE__ = 'loading';

function cleanMText(raw) {
  if (!raw) return '';
  var text = String(raw)
    .replace(/\\P/gi, '\n')
    .replace(/\\[Uu]\+([0-9A-Fa-f]{4,8})/g, (_, hex) => {
      try {
        return String.fromCodePoint(parseInt(hex, 16));
      } catch (e) {
        return '';
      }
    })
    .replace(/\\[A-Za-z0-9.;]+/g, '');

  if (text.includes(';')) {
    text = text.split(';').pop();
  }

  return text
    .replace(/%%[Cc]/g, 'Ø')
    .replace(/[{}]/g, '')
    .replace(/^\|[\w|]+/, '')
    .trim();
}

function readEntityText(entity) {
  if (!entity) return '';

  if (entity.type === 'TEXT') {
    return String(entity.text ?? '').trim();
  }

  if (entity.type === 'MTEXT') {
    return cleanMText(entity.text);
  }

  if (entity.type === 'ATTRIB') {
    const payload = entity.text;
    if (typeof payload === 'string') return payload.trim();
    if (payload && typeof payload.text === 'string') return payload.text.trim();
  }

  return '';
}

function readEntityPosition(entity) {
  if (!entity) return null;

  if (entity.type === 'TEXT') {
    const pt = entity.startPoint;
    if (pt && (pt.x != null || pt.y != null)) {
      return { x: Number(pt.x) || 0, y: Number(pt.y) || 0 };
    }
  }

  if (entity.type === 'MTEXT') {
    const pt = entity.insertionPoint;
    if (pt && (pt.x != null || pt.y != null)) {
      return { x: Number(pt.x) || 0, y: Number(pt.y) || 0 };
    }
  }

  if (entity.type === 'ATTRIB') {
    const pt = entity.text?.startPoint ?? entity.alignmentPoint;
    if (pt && (pt.x != null || pt.y != null)) {
      return { x: Number(pt.x) || 0, y: Number(pt.y) || 0 };
    }
  }

  return null;
}

function pushTextEntry(texts, entityType, text, entity) {
  const position = readEntityPosition(entity);
  const layer = entity?.layer ? String(entity.layer) : undefined;
  const entry = { entityType, text };
  if (position) {
    entry.x = position.x;
    entry.y = position.y;
  }
  if (layer) entry.layer = layer;
  texts.push(entry);
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
          const entityType = entity.type;
          if (entityType !== 'TEXT' && entityType !== 'MTEXT' && entityType !== 'ATTRIB') {
            continue;
          }

          const rawText = readEntityText(entity);
          if (!rawText) continue;

          if (entityType === 'MTEXT') {
            for (const line of rawText.split('\n')) {
              const trimmed = line.trim();
              if (trimmed) pushTextEntry(texts, 'MTEXT', trimmed, entity);
            }
            continue;
          }

          pushTextEntry(texts, entityType, rawText, entity);
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
