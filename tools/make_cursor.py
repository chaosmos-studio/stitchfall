"""Draw the small needle and thread pointer used by the desktop game."""

from pathlib import Path

from PIL import Image, ImageDraw


root = Path(__file__).resolve().parents[1]
image = Image.new("RGBA", (192, 192))
draw = ImageDraw.Draw(image)
draw.line([(22, 20), (120, 120)], fill="#fff3db", width=20, joint="curve")
draw.line([(22, 20), (120, 120)], fill="#493a37", width=11, joint="curve")
draw.ellipse((92, 91, 137, 137), fill="#f7e8cd", outline="#493a37", width=8)
draw.arc((103, 108, 172, 178), 205, 560, fill="#b35d52", width=10)
draw.ellipse((157, 155, 173, 171), fill="#b35d52")
image.resize((48, 48), Image.Resampling.LANCZOS).save(root / "assets" / "art" / "sewing_cursor.png")
