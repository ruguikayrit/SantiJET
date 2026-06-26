window.__SANTIJET_DWG_MODULE__ = 'loading';

function distance(a, b) {
  const dx = (b.x ?? 0) - (a.x ?? 0);
  const dy = (b.y ?? 0) - (a.y ?? 0);
  const dz = (b.z ?? 0) - (a.z ?? 0);
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

function polylineLength(entity) {
  const vertices = entity.vertices ?? [];
  if (vertices.length < 2) return 0;

  let total = 0;
  for (let i = 1; i < vertices.length; i++) {
    total += distance(vertices[i - 1], vertices[i]);
  }

  const flag = entity.flag ?? 0;
  const closed = (flag & 1) === 1;
  if (closed && vertices.length > 2) {
    total += distance(vertices[vertices.length - 1], vertices[0]);
  }
  return total;
}

(async () => {
  try {
    const { Dwg_File_Type, LibreDwg } = await import('./libredwg-web.js');
    const wasmUrl = new URL('./wasm/', import.meta.url).href;
    const libredwg = await LibreDwg.create(wasmUrl);

    window.santijetExtractDwgSegments = async (bytesArray) => {
      const bytes = bytesArray instanceof Uint8Array
        ? bytesArray
        : new Uint8Array(bytesArray);

      const dwg = libredwg.dwg_read_data(bytes, Dwg_File_Type.DWG);
      if (!dwg) {
        throw new Error('DWG dosyası okunamadı. Dosya bozuk veya desteklenmeyen sürüm olabilir.');
      }

      try {
        const db = libredwg.convert(dwg);
        const segments = [];

        for (const entity of db.entities ?? []) {
          const layerName = entity.layer ?? '0';

          if (entity.type === 'LINE') {
            segments.push({
              layerName,
              length: distance(entity.startPoint, entity.endPoint),
            });
            continue;
          }

          if (
            entity.type === 'LWPOLYLINE' ||
            entity.type === 'POLYLINE2D' ||
            entity.type === 'POLYLINE3D'
          ) {
            const length = polylineLength(entity);
            if (length > 0) {
              segments.push({ layerName, length });
            }
          }
        }

        return segments;
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
