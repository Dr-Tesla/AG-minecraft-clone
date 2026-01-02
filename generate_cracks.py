"""
Generate crack textures for block breaking animation.
Creates a separate texture file with 4 crack stages.
"""
from PIL import Image
import random

# Create 64x16 image (4 crack stages * 16 pixels each)
crack_atlas = Image.new('RGBA', (64, 16), (0, 0, 0, 0))

def draw_crack_stage(start_x, intensity):
    """Draw a crack stage with increasing crack coverage."""
    random.seed(42)  # Consistent pattern
    
    for y in range(16):
        for x in range(16):
            # Probability of crack increases with intensity
            if random.random() < intensity * 0.4:
                # Draw crack pixel (dark gray, semi-transparent)
                alpha = int(200 * intensity)
                crack_atlas.putpixel((start_x + x, y), (20, 20, 20, alpha))
            else:
                # Transparent
                crack_atlas.putpixel((start_x + x, y), (0, 0, 0, 0))
    
    # Add crack lines
    num_lines = int(intensity * 8) + 1
    for _ in range(num_lines):
        start_y = random.randint(0, 15)
        start_x_line = random.randint(0, 10)
        length = random.randint(3, 10)
        
        for i in range(length):
            px = start_x_line + i + random.randint(-1, 1)
            py = start_y + random.randint(-1, 1)
            if 0 <= px < 16 and 0 <= py < 16:
                alpha = int(220 * intensity)
                crack_atlas.putpixel((start_x + px, py), (10, 10, 10, alpha))

# Generate 4 crack stages with increasing intensity
for stage in range(4):
    intensity = (stage + 1) / 4.0  # 0.25, 0.5, 0.75, 1.0
    draw_crack_stage(stage * 16, intensity)

# Save the crack atlas
output_path = 'assets/crack_atlas.png'
crack_atlas.save(output_path)
print(f"Created crack atlas: {output_path} ({crack_atlas.size[0]}x{crack_atlas.size[1]})")
