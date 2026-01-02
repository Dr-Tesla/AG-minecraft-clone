"""
main.py - Minecraft Clone Entry Point

This is the main entry point for the Minecraft clone game.
Initializes Ursina, creates the world and player, and runs the game loop.

Controls:
    WASD - Move
    Mouse - Look around
    Space - Jump
    Left Click - Remove block
    Right Click - Place block
    Escape - Unlock mouse / Exit
"""

from ursina import Ursina, window, application, Sky, color, held_keys, mouse, Entity, Text, Button
from ursina import camera

from world import World
from player import Player
from hotbar import Hotbar


def main():
    """Main entry point."""
    # Initialize Ursina application
    app = Ursina(
        title='Minecraft Clone',
        borderless=False,
        fullscreen=False,
        development_mode=False,
        vsync=True
    )
    
    # Window settings
    window.size = (1280, 720)
    window.fps_counter.enabled = True
    window.exit_button.visible = False
    
    # Create sky
    sky = Sky()
    
    # Create world manager
    world = World()
    
    # Create player at a reasonable starting position
    # Start above the terrain so they fall to the ground
    hotbar = Hotbar()
    player = Player(world, hotbar=hotbar, position=(8, 50, 8))
    
    # Initial chunk loading around player
    world.load_chunks_around(player.position.x, player.position.y, player.position.z)
    
    # Instructions text (fades after a few seconds)
    instructions = Text(
        text='WASD: Move | Space: Jump | 1-8: Select Block | Left/Right Click: Break/Place | ESC: Pause',
        origin=(0, 0),
        y=0.45,
        scale=0.8,
        color=color.white
    )
    
    def hide_instructions():
        instructions.enabled = False
    
    from ursina import invoke
    invoke(hide_instructions, delay=5)
    
    # Pause menu elements (hidden by default)
    pause_overlay = Entity(
        parent=camera.ui,
        model='quad',
        color=color.rgba(0, 0, 0, 150),
        scale=(2, 2),
        z=-0.5,
        enabled=False
    )
    
    pause_text = Text(
        text='PAUSED',
        parent=camera.ui,
        origin=(0, 0),
        y=0.25,
        z=-1,
        scale=2,
        color=color.white,
        enabled=False
    )
    
    # State tracking
    game_paused = [False]
    current_tab = ['main']  # 'main' or 'settings'
    
    # Settings values
    settings = {
        'fov': 90,
        'speed': 5.0
    }
    camera.fov = settings['fov']
    
    # ===== MAIN TAB ELEMENTS =====
    def quit_game():
        application.quit()
    
    quit_button = Button(
        text='Quit Game',
        parent=camera.ui,
        scale=(0.3, 0.08),
        y=-0.1,
        z=-1,
        color=color.red,
        highlight_color=color.orange,
        enabled=False,
        on_click=quit_game
    )
    
    # Forward declarations for tab switching
    main_tab_elements = []
    settings_tab_elements = []
    
    def show_main_tab():
        current_tab[0] = 'main'
        for elem in main_tab_elements:
            elem.enabled = True
        for elem in settings_tab_elements:
            elem.enabled = False
    
    def show_settings_tab():
        current_tab[0] = 'settings'
        for elem in main_tab_elements:
            elem.enabled = False
        for elem in settings_tab_elements:
            elem.enabled = True
    
    settings_button = Button(
        text='Settings',
        parent=camera.ui,
        scale=(0.3, 0.08),
        y=0.0,
        z=-1,
        color=color.gray,
        highlight_color=color.white,
        enabled=False,
        on_click=show_settings_tab
    )
    
    # ===== SETTINGS TAB ELEMENTS =====
    settings_title = Text(
        text='SETTINGS',
        parent=camera.ui,
        origin=(0, 0),
        y=0.15,
        z=-1,
        scale=1.5,
        color=color.yellow,
        enabled=False
    )
    
    # FOV Controls
    fov_label = Text(
        text=f"FOV: {settings['fov']}",
        parent=camera.ui,
        origin=(0, 0),
        y=0.05,
        z=-1,
        scale=1,
        color=color.white,
        enabled=False
    )
    
    def decrease_fov():
        settings['fov'] = max(30, settings['fov'] - 10)
        camera.fov = settings['fov']
        fov_label.text = f"FOV: {settings['fov']}"
    
    def increase_fov():
        settings['fov'] = min(120, settings['fov'] + 10)
        camera.fov = settings['fov']
        fov_label.text = f"FOV: {settings['fov']}"
    
    fov_minus_btn = Button(
        text='-',
        parent=camera.ui,
        scale=(0.08, 0.06),
        x=-0.18,
        y=0.05,
        z=-1,
        color=color.gray,
        highlight_color=color.white,
        enabled=False,
        on_click=decrease_fov
    )
    
    fov_plus_btn = Button(
        text='+',
        parent=camera.ui,
        scale=(0.08, 0.06),
        x=0.18,
        y=0.05,
        z=-1,
        color=color.gray,
        highlight_color=color.white,
        enabled=False,
        on_click=increase_fov
    )
    
    # Speed Controls
    speed_label = Text(
        text=f"Speed: {settings['speed']:.1f}",
        parent=camera.ui,
        origin=(0, 0),
        y=-0.05,
        z=-1,
        scale=1,
        color=color.white,
        enabled=False
    )
    
    def decrease_speed():
        settings['speed'] = max(1.0, settings['speed'] - 1.0)
        player.speed = settings['speed']
        speed_label.text = f"Speed: {settings['speed']:.1f}"
    
    def increase_speed():
        settings['speed'] = min(20.0, settings['speed'] + 1.0)
        player.speed = settings['speed']
        speed_label.text = f"Speed: {settings['speed']:.1f}"
    
    speed_minus_btn = Button(
        text='-',
        parent=camera.ui,
        scale=(0.08, 0.06),
        x=-0.18,
        y=-0.05,
        z=-1,
        color=color.gray,
        highlight_color=color.white,
        enabled=False,
        on_click=decrease_speed
    )
    
    speed_plus_btn = Button(
        text='+',
        parent=camera.ui,
        scale=(0.08, 0.06),
        x=0.18,
        y=-0.05,
        z=-1,
        color=color.gray,
        highlight_color=color.white,
        enabled=False,
        on_click=increase_speed
    )
    
    back_button = Button(
        text='Back',
        parent=camera.ui,
        scale=(0.2, 0.07),
        y=-0.18,
        z=-1,
        color=color.azure,
        highlight_color=color.cyan,
        enabled=False,
        on_click=show_main_tab
    )
    
    # Define hide_pause_menu first (needed by resume_game)
    def hide_pause_menu():
        pause_overlay.enabled = False
        pause_text.enabled = False
        for elem in main_tab_elements:
            elem.enabled = False
        for elem in settings_tab_elements:
            elem.enabled = False
    
    def resume_game():
        mouse.locked = True
        mouse.visible = False
        hide_pause_menu()
        game_paused[0] = False
        current_tab[0] = 'main'
        # Set cooldown to prevent the resume click from breaking a block
        player._click_cooldown = 0.25
    
    resume_button = Button(
        text='Resume',
        parent=camera.ui,
        scale=(0.3, 0.08),
        y=0.1,
        z=-1,
        color=color.azure,
        highlight_color=color.cyan,
        enabled=False,
        on_click=resume_game
    )
    
    # Populate tab element lists (now that all buttons are defined)
    main_tab_elements.extend([resume_button, settings_button, quit_button])
    settings_tab_elements.extend([
        settings_title, fov_label, fov_minus_btn, fov_plus_btn,
        speed_label, speed_minus_btn, speed_plus_btn, back_button
    ])
    
    def show_pause_menu():
        pause_overlay.enabled = True
        pause_text.enabled = True
        current_tab[0] = 'main'
        show_main_tab()
    
    # Create an input handler entity for proper key detection
    class InputHandler(Entity):
        def input(self, key):
            if key == 'q':
                application.quit()
            
            if key == 'escape':
                if mouse.locked:
                    # Pause the game
                    mouse.locked = False
                    mouse.visible = True
                    show_pause_menu()
                    game_paused[0] = True
                else:
                    # Resume the game
                    resume_game()
    
    input_handler = InputHandler()
    
    # Game loop entity - handles chunk loading and frustum culling
    class GameLoop(Entity):
        def update(self):
            # Update chunk loading based on player position
            world.load_chunks_around(player.position.x, player.position.y, player.position.z)
            
            # Update frustum culling
            world.update_frustum_culling()
    
    game_loop = GameLoop()
    
    # Run the application
    app.run()


if __name__ == '__main__':
    main()
