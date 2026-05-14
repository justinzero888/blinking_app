"""Generate placeholder avatar PNGs for the 4 AI personas."""
from PIL import Image, ImageDraw, ImageFont
import os

AVATARS = [
    ("kael",  "#708090", "📝"),
    ("elara", "#4CAF50", "🌿"),
    ("rush",  "#FF8C00", "⚡"),
    ("marcus","#757575", "⚔️"),
]

SIZE = 256
FONT_SIZE = 120

output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "avatars")
os.makedirs(output_dir, exist_ok=True)

for name, hex_color, emoji in AVATARS:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colored circle background
    color = tuple(int(hex_color[i:i+2], 16) for i in (1, 3, 5)) + (255,)
    margin = 8
    draw.ellipse([margin, margin, SIZE - margin, SIZE - margin], fill=color)

    # Emoji in center
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", FONT_SIZE)
    except (OSError, IOError):
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), emoji, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (SIZE - tw) / 2 - bbox[0]
    y = (SIZE - th) / 2 - bbox[1]
    draw.text((x, y), emoji, font=font, embedded_color=True)

    path = os.path.join(output_dir, f"{name}.png")
    img.save(path, "PNG")
    print(f"Created {path} ({os.path.getsize(path)} bytes)")

print("Done.")
