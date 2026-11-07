"""Prepare a Godot web export for static hosting with a per-file size limit."""

import hashlib
import gzip
import json
import shutil
from pathlib import Path


root = Path.cwd() / "build" / "web"
(root.parent / ".gdignore").touch()
chunk_size = 4 * 1024 * 1024
assets = {}
for file_name, content_type in (("index.wasm", "application/wasm"), ("index.pck", "application/octet-stream")):
    source = root / file_name
    raw = source.read_bytes()
    if file_name.endswith(".wasm"):
        assert raw[:4] == b"\0asm", "Not a WebAssembly build"
    else:
        assert b"ECFG" in raw, "The game pack has no project configuration"
    for old in root.glob(f"{file_name}.part*"):
        old.unlink()
    for old in root.glob(f"{file_name}.gz.part*"):
        old.unlink()
    parts = []
    for offset in range(0, len(raw), chunk_size):
        name = f"{file_name}.part{offset // chunk_size}"
        (root / name).write_bytes(raw[offset : offset + chunk_size])
        parts.append(name)
    assert b"".join((root / name).read_bytes() for name in parts) == raw
    assets[file_name] = {
        "parts": parts,
        "size": len(raw),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "content_type": content_type,
    }
    if file_name.endswith(".wasm"):
        compressed = gzip.compress(raw, compresslevel=9, mtime=0)
        compressed_parts = []
        for offset in range(0, len(compressed), chunk_size):
            name = f"{file_name}.gz.part{offset // chunk_size}"
            (root / name).write_bytes(compressed[offset : offset + chunk_size])
            compressed_parts.append(name)
        assert gzip.decompress(b"".join((root / name).read_bytes() for name in compressed_parts)) == raw
        assets[file_name]["gzip_parts"] = compressed_parts
        assets[file_name]["gzip_size"] = len(compressed)
    source.unlink()

loader = """// Stream the engine and game pack from static-host-friendly chunks.
(() => {
  const nativeFetch = window.fetch.bind(window);
  const assets = ASSETS;
  const base = new URL('.', document.currentScript.src);
  // itch's HTML host expands gzip chunks while extracting the uploaded ZIP.
  const useGzip = typeof DecompressionStream === 'function' && !location.hostname.endsWith('.itch.zone');
  const selected = Object.fromEntries(Object.entries(assets).map(([name, asset]) => [name,
    useGzip && asset.gzip_parts
      ? {parts: asset.gzip_parts, size: asset.gzip_size, gzip: true}
      : {parts: asset.parts, size: asset.size, gzip: false}
  ]));
  const received = Object.fromEntries(Object.keys(assets).map(name => [name, 0]));
  const total = Object.values(selected).reduce((sum, asset) => sum + asset.size, 0);
  const report = () => window.stitchfallDownload?.(Object.values(received).reduce((sum, size) => sum + size, 0), total);
  report();
  window.fetch = async function(resource, options) {
    const url = new URL(typeof resource === 'string' ? resource : resource.url || String(resource), location.href);
    const name = Object.keys(assets).find(candidate => url.href === new URL(candidate, base).href);
    if (!name) return nativeFetch(resource, options);
    const asset = assets[name];
    const download = selected[name];
    const stream = new ReadableStream({async start(controller) {
      try {
        const prefetchWindow = 2;
        const pending = new Map();
        const requestPart = index => {
          const partUrl = new URL(download.parts[index], base);
          partUrl.searchParams.set('v', asset.sha256.slice(0, 12));
          return nativeFetch(partUrl, options).then(response => ({response}), error => ({error}));
        };
        for (let index = 0; index < Math.min(prefetchWindow, download.parts.length); index++) {
          pending.set(index, requestPart(index));
        }
        for (let index = 0; index < download.parts.length; index++) {
          const result = await pending.get(index);
          pending.delete(index);
          if (result.error) throw result.error;
          const response = result.response;
          if (!response.ok) throw new Error('Game download failed: ' + response.status);
          const next = index + prefetchWindow;
          if (next < download.parts.length) pending.set(next, requestPart(next));
          const reader = response.body.getReader();
          while (true) {
            const {done, value} = await reader.read();
            if (done) break;
            received[name] += value.byteLength;
            report();
            controller.enqueue(value);
          }
        }
        controller.close();
      } catch (error) {controller.error(error);}
    }});
    const decoded = download.gzip ? stream.pipeThrough(new DecompressionStream('gzip')) : stream;
    return new Response(decoded, {headers: {'Content-Type': asset.content_type, 'Content-Length': String(asset.size)}});
  };
})();
""".replace("ASSETS", json.dumps(assets))
(root / "wasm-loader.js").write_text(loader)
html = root / "index.html"
html_text = html.read_text()
loader_tag = 'src="wasm-loader.js"'
assert loader_tag in html_text
html.write_text(html_text.replace(loader_tag, f'src="wasm-loader.js?v={assets["index.pck"]["sha256"][:12]}"'))
(root / ".nojekyll").touch()
for font_name in ("Threadline-Woven.ttf", "Darn-UI.ttf"):
    shutil.copyfile(Path.cwd() / "assets" / "fonts" / font_name, root / font_name)
shutil.copyfile(Path.cwd() / "assets" / "art" / "sewing_cursor.png", root / "sewing_cursor.png")
shutil.copyfile(Path.cwd() / "assets" / "art" / "home_woodland.webp", root / "home_woodland.webp")
shutil.copyfile(Path.cwd() / "assets" / "art" / "logo_label.png", root / "logo_label.png")
for icon in (Path.cwd() / "web" / "icons").glob("*.png"):
    shutil.copyfile(icon, root / icon.name)
for pose in range(4):
    shutil.copyfile(Path.cwd() / "web" / f"loader_pose_{pose}.webp", root / f"loader_pose_{pose}.webp")
(root / "build-info.json").write_text(
    json.dumps(assets, indent=2) + "\n"
)
for imported in root.glob("*.import"):
    imported.unlink()
assert max(path.stat().st_size for path in root.iterdir() if path.is_file()) <= chunk_size
print("Prepared web build: " + ", ".join(f"{name}: {len(asset['parts'])} chunks" for name, asset in assets.items()))
