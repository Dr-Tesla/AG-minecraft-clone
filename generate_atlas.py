"""
Generate a proper texture atlas for the Minecraft clone.
Creates a 144x16 pixel image with 9 textures side by side.
"""
from PIL import Image, ImageDraw
import os
import random

# Create 144x16 image (9 textures * 16 pixels each)
atlas = Image.new('RGBA', (144, 16), (0, 0, 0, 0))

def draw_texture(start_x, pattern_func):
    """Draw a 16x16 texture starting at start_x."""
    for y in range(16):
        for x in range(16):
            random.seed(x * 1000 + y * 37 + start_x)
            color = pattern_func(x, y)
            atlas.putpixel((start_x + x, y), color)

# Texture 0: Grass Top (bright green)
def grass_top(x, y):
    g = 140 + random.randint(-20, 20)
    return (60, g, 60, 255)

# Texture 1: Grass Side (dirt with green strip at top)
def grass_side(x, y):
    if y < 3:  # Green strip at top
        g = 130 + random.randint(-10, 10)
        return (60, g, 60, 255)
    else:  # Dirt underneath
        r = 139 + random.randint(-15, 15)
        return (r, int(r*0.55), int(r*0.25), 255)

# Texture 2: Dirt (brown)
def dirt(x, y):
    r = 139 + random.randint(-20, 20)
    return (r, int(r*0.55), int(r*0.25), 255)

# Texture 3: Stone (gray speckled)
def stone(x, y):
    g = 130 + random.randint(-25, 15)
    return (g, g, g, 255)

# Texture 4: Wood (dark brown bark with rings - very different from dirt)
def wood(x, y):
    # Much darker, reddish-brown bark
    base = 70 + random.randint(-10, 10)
    # Add ring pattern
    dist = abs(x - 8) + abs(y - 8)
    if dist % 4 < 2:
        base -= 15
    return (base + 30, base, base - 20, 255)

# Texture 5: Sand (yellow/tan)
def sand(x, y):
    r = 230 + random.randint(-10, 10)
    g = 210 + random.randint(-10, 10)
    b = 150 + random.randint(-15, 15)
    return (r, g, b, 255)

# Texture 6: Cobblestone (irregular gray blocks)
def cobblestone(x, y):
    # Create blocky irregular pattern
    block_id = ((x // 4) * 7 + (y // 4) * 13) % 5
    base = 100 + block_id * 15 + random.randint(-10, 10)
    # Darker lines between blocks
    if x % 4 == 0 or y % 4 == 0:
        base -= 30
    return (base, base, base, 255)

# Texture 7: Planks (light brown with horizontal lines)
def planks(x, y):
    # Light brown base
    r = 190 + random.randint(-10, 10)
    g = 140 + random.randint(-10, 10)
    b = 90 + random.randint(-10, 10)
    # Horizontal wood grain lines
    if y % 4 == 0:
        r -= 30
        g -= 20
        b -= 15
    # Vertical plank separators
    if x % 8 == 0:
        r -= 25
        g -= 20
        b -= 15
    return (r, g, b, 255)

# Texture 8: Leaves (bright green with gaps)
def leaves(x, y):
    g = 120 + random.randint(-30, 30)
    # Some transparency for leaf gaps
    alpha = 255 if random.random() > 0.15 else 0
    return (40, g, 40, alpha)

# Generate all textures
textures = [grass_top, grass_side, dirt, stone, wood, sand, cobblestone, planks, leaves]
for i, tex_func in enumerate(textures):
    draw_texture(i * 16, tex_func)

# Save the atlas
output_path = 'assets/texture_atlas.png'
atlas.save(output_path)
print(f"Created texture atlas: {output_path} ({atlas.size[0]}x{atlas.size[1]})")
