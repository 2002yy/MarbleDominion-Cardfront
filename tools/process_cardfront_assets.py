# process_cardfront_assets.py
# v0.1: 1024 source -> runtime PNG (resize, transparent bg for devices)
# Usage: python tools/process_cardfront_assets.py
import os
from PIL import Image, ImageFilter

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC  = os.path.join(BASE, "assets", "cardfront")
DST  = os.path.join(BASE, "assets", "cardfront_runtime")

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def resize_to(src_path, dst_path, size, keep_alpha=False):
    img = Image.open(src_path).convert("RGBA")
    if not keep_alpha:
        bg = remove_bg_simple(img)
        img = bg
    img = img.resize(size, Image.LANCZOS)
    img.save(dst_path, "PNG")
    print(f"  -> {os.path.basename(dst_path)}  {size[0]}x{size[1]}")

def remove_bg_simple(img):
    """Auto-remove background by sampling corners and feathering edges."""
    w, h = img.size
    pixels = img.load()
    corners = [
        pixels[0, 0], pixels[w-1, 0],
        pixels[0, h-1], pixels[w-1, h-1],
        pixels[w//2, 0], pixels[0, h//2],
    ]
    bg_r = int(sum(c[0] for c in corners) / len(corners))
    bg_g = int(sum(c[1] for c in corners) / len(corners))
    bg_b = int(sum(c[2] for c in corners) / len(corners))
    threshold = 60
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if abs(r - bg_r) < threshold and abs(g - bg_g) < threshold and abs(b - bg_b) < threshold:
                pixels[x, y] = (r, g, b, 0)
    return img

def process_cards():
    print("[cards] 1024 -> 512")
    src_dir = os.path.join(SRC, "卡牌插图_cards_illustrations")
    dst_dir = os.path.join(DST, "卡牌插图_cards", "512")
    ensure_dir(dst_dir)
    for f in os.listdir(src_dir):
        if f.endswith(".png"):
            resize_to(os.path.join(src_dir, f), os.path.join(dst_dir, f), (512, 512))

def process_devices():
    print("[devices] 1024 -> 96 (transparent bg)")
    src_dir = os.path.join(SRC, "装置地图精灵_devices_map_sprites")
    dst_dir = os.path.join(DST, "装置精灵_devices", "96")
    ensure_dir(dst_dir)
    for f in os.listdir(src_dir):
        if f.endswith(".png"):
            resize_to(os.path.join(src_dir, f), os.path.join(dst_dir, f), (96, 96))

def process_icons():
    print("[icons] 1024 -> 48x48")
    src_dir = os.path.join(SRC, "装置图标_devices_icons")
    dst_dir = os.path.join(DST, "装置图标_icons", "48")
    ensure_dir(dst_dir)
    for f in os.listdir(src_dir):
        if f.endswith(".png"):
            resize_to(os.path.join(src_dir, f), os.path.join(dst_dir, f), (48, 48))

def process_vfx():
    print("[vfx] 1024 -> 128 (keep alpha)")
    src_dir = os.path.join(SRC, "特效纹理_vfx_textures")
    dst_dir = os.path.join(DST, "视觉特效_vfx", "128")
    ensure_dir(dst_dir)
    for f in os.listdir(src_dir):
        if f.endswith(".png"):
            img = Image.open(os.path.join(src_dir, f)).convert("RGBA")
            img = img.resize((128, 128), Image.LANCZOS)
            img.save(os.path.join(dst_dir, f), "PNG")
            print(f"  -> {f}  128x128")

if __name__ == "__main__":
    process_cards()
    process_devices()
    process_icons()
    process_vfx()
    print("\nDone. Runtime assets in assets/cardfront_runtime/")
