from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
RUNTIME_ROOT = (
    ROOT / "assets" / "cardfront_runtime" / "战场实体_battlefield_entities" / "256"
)
PREVIEW_ROOT = ROOT / "assets" / "cardfront" / "战场实体_battlefield_entities" / "previews"
FRAME_SIZE = 256
OUTLINE = (30, 38, 46, 255)
STEEL = (104, 128, 144, 255)
LIGHT_STEEL = (181, 205, 213, 255)
GOLD = (248, 188, 62, 255)
CYAN = (47, 205, 229, 255)
RED = (232, 75, 63, 255)
GREEN = (91, 204, 119, 255)
WHITE = (241, 247, 244, 255)

SPECS = {
    "repair_unit": {
        "states": {"idle": 4, "move": 6, "repair": 6, "hit": 4, "death": 6},
        "draw": "repair",
    },
    "armored_guard": {
        "states": {"idle": 4, "move": 6, "block": 6, "hit": 4, "death": 6},
        "draw": "guard",
    },
    "sapper_unit": {
        "states": {
            "idle": 4,
            "move": 6,
            "attack": 6,
            "detonate": 6,
            "hit": 4,
            "death": 6,
        },
        "draw": "sapper",
    },
    "scout_unit": {
        "states": {"idle": 4, "move": 6, "guide": 6, "hit": 4, "death": 6},
        "draw": "scout",
    },
}


def ellipse(draw: ImageDraw.ImageDraw, box, fill, width: int = 5) -> None:
    draw.ellipse(box, fill=fill, outline=OUTLINE, width=width)


def rounded(draw: ImageDraw.ImageDraw, box, radius: int, fill, width: int = 5) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=OUTLINE, width=width)


def polygon(draw: ImageDraw.ImageDraw, points, fill, width: int = 5) -> None:
    draw.polygon(points, fill=fill)
    draw.line([*points, points[0]], fill=OUTLINE, width=width, joint="curve")


def stroke(draw: ImageDraw.ImageDraw, points, fill=OUTLINE, width: int = 7) -> None:
    draw.line(points, fill=fill, width=width, joint="curve")


def phase(index: int, count: int) -> float:
    return float(index) / float(max(1, count - 1))


def loop_phase(index: int, count: int) -> float:
    return math.tau * float(index) / float(max(1, count))


def pose_values(state: str, index: int, count: int) -> tuple[float, float, float]:
    t = phase(index, count)
    bob = math.sin(loop_phase(index, count)) * 3.0
    lean = 0.0
    fade = 1.0
    if state == "move":
        bob = abs(math.sin(loop_phase(index, count))) * -5.0
        lean = math.sin(loop_phase(index, count)) * 4.0
    elif state == "hit":
        lean = math.sin(t * math.pi) * -12.0
    elif state == "death":
        lean = t * 22.0
        fade = max(0.15, 1.0 - t * 0.85)
        bob = t * 28.0
    return bob, lean, fade


def draw_shadow(draw: ImageDraw.ImageDraw, width: int, alpha: int = 65) -> None:
    draw.ellipse(
        (128 - width, 222, 128 + width, 238),
        fill=(28, 37, 42, alpha),
    )


def draw_repair(state: str, index: int, count: int) -> Image.Image:
    image = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
    draw = ImageDraw.Draw(image)
    t = phase(index, count)
    bob, lean, fade = pose_values(state, index, count)
    alpha = int(255 * fade)
    body_y = 135 + bob
    draw_shadow(draw, 45, int(60 * fade))
    if state == "repair":
        bob = -math.sin(t * math.pi) * 5
        body_y = 135 + bob
        for ray in range(5):
            angle = -1.15 + ray * 0.26
            start = (177 + math.cos(angle) * 15, 196 + math.sin(angle) * 15)
            end = (177 + math.cos(angle) * (22 + 8 * t), 196 + math.sin(angle) * (22 + 8 * t))
            stroke(draw, [start, end], GOLD, 4)
    leg_swing = math.sin(loop_phase(index, count)) * 9 if state == "move" else 0
    stroke(draw, [(108 + lean, body_y + 44), (101 - leg_swing, 213 + bob)], OUTLINE, 15)
    stroke(draw, [(147 + lean, body_y + 44), (155 + leg_swing, 213 + bob)], OUTLINE, 15)
    ellipse(draw, (88 - leg_swing, 205 + bob, 113 - leg_swing, 225 + bob), (72, 91, 105, alpha))
    ellipse(draw, (144 + leg_swing, 205 + bob, 169 + leg_swing, 225 + bob), (72, 91, 105, alpha))
    rounded(draw, (91 + lean, body_y, 164 + lean, body_y + 65), 20, (41, 146, 185, alpha))
    rounded(draw, (103 + lean, body_y + 12, 152 + lean, body_y + 47), 12, (65, 184, 213, alpha), 4)
    ellipse(draw, (105 + lean, body_y - 35, 151 + lean, body_y + 8), (169, 203, 211, alpha))
    rounded(draw, (113 + lean, body_y - 21, 143 + lean, body_y - 3), 8, (44, 57, 66, alpha), 3)
    ellipse(draw, (120 + lean, body_y - 17, 128 + lean, body_y - 9), (92, 231, 255, alpha), 2)
    ellipse(draw, (134 + lean, body_y - 17, 142 + lean, body_y - 9), (92, 231, 255, alpha), 2)
    arm_angle = -0.9 + math.sin(t * math.pi) * 1.25 if state == "repair" else -0.2
    elbow = (166 + lean + math.cos(arm_angle) * 21, body_y + 23 + math.sin(arm_angle) * 21)
    hand = (166 + lean + math.cos(arm_angle) * 41, body_y + 23 + math.sin(arm_angle) * 41)
    stroke(draw, [(160 + lean, body_y + 22), elbow, hand], OUTLINE, 13)
    ellipse(draw, (hand[0] - 8, hand[1] - 8, hand[0] + 8, hand[1] + 8), GOLD, 3)
    tool_angle = arm_angle + 0.25
    tool_end = (hand[0] + math.cos(tool_angle) * 31, hand[1] + math.sin(tool_angle) * 31)
    stroke(draw, [hand, tool_end], LIGHT_STEEL, 8)
    ellipse(draw, (tool_end[0] - 10, tool_end[1] - 10, tool_end[0] + 10, tool_end[1] + 10), LIGHT_STEEL, 4)
    stroke(draw, [(93 + lean, body_y + 22), (76 + lean, body_y + 45)], OUTLINE, 13)
    if state == "death":
        image = image.rotate(-lean, resample=Image.Resampling.BICUBIC, center=(128, 214))
    return image


def draw_guard(state: str, index: int, count: int) -> Image.Image:
    image = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
    draw = ImageDraw.Draw(image)
    t = phase(index, count)
    bob, lean, fade = pose_values(state, index, count)
    alpha = int(255 * fade)
    body_y = 126 + bob
    draw_shadow(draw, 52, int(70 * fade))
    if state == "block":
        lean = -8 * math.sin(t * math.pi)
        for radius in [35, 47]:
            draw.arc(
                (46 - radius, 130 - radius, 46 + radius, 130 + radius),
                -70,
                70,
                fill=(88, 220, 255, int(210 * math.sin(t * math.pi))),
                width=5,
            )
    leg = math.sin(loop_phase(index, count)) * 8 if state == "move" else 0
    stroke(draw, [(117 + lean, body_y + 63), (110 - leg, 216 + bob)], OUTLINE, 18)
    stroke(draw, [(151 + lean, body_y + 63), (159 + leg, 216 + bob)], OUTLINE, 18)
    rounded(draw, (91 + lean, body_y, 174 + lean, body_y + 74), 19, (77, 101, 122, alpha))
    polygon(
        draw,
        [(104 + lean, body_y + 8), (132 + lean, body_y - 4), (163 + lean, body_y + 10),
         (157 + lean, body_y + 49), (132 + lean, body_y + 65), (108 + lean, body_y + 49)],
        (102, 134, 158, alpha),
        4,
    )
    rounded(draw, (109 + lean, body_y - 39, 157 + lean, body_y + 2), 14, (148, 171, 182, alpha))
    polygon(
        draw,
        [(105 + lean, body_y - 25), (133 + lean, body_y - 47), (161 + lean, body_y - 25)],
        (87, 113, 130, alpha),
        4,
    )
    rounded(draw, (116 + lean, body_y - 22, 151 + lean, body_y - 8), 6, (41, 50, 58, alpha), 3)
    stroke(draw, [(168 + lean, body_y + 20), (190 + lean, body_y + 51)], OUTLINE, 16)
    shield_x = 48 + (14 * math.sin(t * math.pi) if state == "block" else 0)
    polygon(
        draw,
        [(shield_x, body_y - 8), (90, body_y + 5), (88, body_y + 65),
         (shield_x + 22, body_y + 91), (shield_x - 4, body_y + 65)],
        (53, 132, 188, alpha),
        6,
    )
    polygon(
        draw,
        [(shield_x + 8, body_y + 15), (shield_x + 27, body_y + 22),
         (shield_x + 24, body_y + 59), (shield_x + 11, body_y + 70)],
        (75, 183, 222, alpha),
        3,
    )
    if state == "hit":
        stroke(draw, [(183, 88), (205, 68)], RED, 7)
        stroke(draw, [(187, 92), (214, 93)], RED, 7)
    if state == "death":
        image = image.rotate(-lean, resample=Image.Resampling.BICUBIC, center=(128, 218))
    return image


def draw_sapper(state: str, index: int, count: int) -> Image.Image:
    image = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
    draw = ImageDraw.Draw(image)
    t = phase(index, count)
    bob, lean, fade = pose_values(state, index, count)
    alpha = int(255 * fade)
    body_y = 137 + bob
    draw_shadow(draw, 43, int(65 * fade))
    if state == "detonate":
        blast = int(18 + 92 * t)
        for radius, color in [
            (blast, (255, 197, 55, int(220 * (1 - t)))),
            (int(blast * 0.68), (244, 93, 52, int(235 * (1 - t)))),
        ]:
            draw.ellipse(
                (128 - radius, 159 - radius, 128 + radius, 159 + radius),
                fill=color,
                outline=OUTLINE,
                width=4,
            )
        if t > 0.45:
            return image
    leg = math.sin(loop_phase(index, count)) * 10 if state == "move" else 0
    stroke(draw, [(112 + lean, body_y + 47), (104 - leg, 215 + bob)], OUTLINE, 15)
    stroke(draw, [(145 + lean, body_y + 47), (154 + leg, 215 + bob)], OUTLINE, 15)
    ellipse(draw, (89 - leg, 205 + bob, 114 - leg, 224 + bob), (66, 76, 83, alpha))
    ellipse(draw, (144 + leg, 205 + bob, 169 + leg, 224 + bob), (66, 76, 83, alpha))
    ellipse(draw, (91 + lean, body_y - 3, 165 + lean, body_y + 65), (126, 70, 65, alpha))
    rounded(draw, (105 + lean, body_y + 8, 151 + lean, body_y + 49), 12, (196, 72, 55, alpha), 4)
    ellipse(draw, (108 + lean, body_y - 39, 151 + lean, body_y + 1), (101, 112, 118, alpha))
    polygon(
        draw,
        [(105 + lean, body_y - 22), (129 + lean, body_y - 44), (154 + lean, body_y - 22)],
        (191, 78, 58, alpha),
        4,
    )
    rounded(draw, (114 + lean, body_y - 18, 146 + lean, body_y - 6), 5, (43, 47, 50, alpha), 3)
    drill_push = 25 * math.sin(t * math.pi) if state == "attack" else 0
    stroke(draw, [(164 + lean, body_y + 25), (180 + lean + drill_push, body_y + 41)], OUTLINE, 14)
    polygon(
        draw,
        [(179 + lean + drill_push, body_y + 29), (218 + lean + drill_push, body_y + 42),
         (179 + lean + drill_push, body_y + 55)],
        GOLD,
        4,
    )
    ellipse(draw, (72 + lean, body_y + 4, 103 + lean, body_y + 37), (54, 58, 61, alpha))
    stroke(draw, [(87 + lean, body_y + 3), (87 + lean, body_y - 16)], GOLD, 5)
    ellipse(draw, (82 + lean, body_y - 24, 92 + lean, body_y - 14), RED, 2)
    if state == "hit":
        stroke(draw, [(69, 111), (49, 90)], RED, 7)
    if state == "death":
        image = image.rotate(-lean, resample=Image.Resampling.BICUBIC, center=(128, 218))
    return image


def draw_scout(state: str, index: int, count: int) -> Image.Image:
    image = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
    draw = ImageDraw.Draw(image)
    t = phase(index, count)
    bob, lean, fade = pose_values(state, index, count)
    hover = math.sin(loop_phase(index, count)) * 6
    if state == "move":
        hover = math.sin(loop_phase(index, count)) * 9
        lean *= 1.5
    alpha = int(255 * fade)
    center_y = 149 + hover + bob
    draw_shadow(draw, 35, int(45 * fade))
    if state == "guide":
        pulse = int(25 + 45 * t)
        for offset in [0, 14]:
            radius = pulse + offset
            draw.arc(
                (128 - radius, center_y - radius, 128 + radius, center_y + radius),
                200,
                340,
                fill=(77, 235, 255, int(215 * (1 - t))),
                width=5,
            )
    wing = 9 * math.sin(loop_phase(index, count))
    polygon(
        draw,
        [(84 + lean, center_y - 2), (42 + lean, center_y - 25 - wing),
         (57 + lean, center_y + 15), (91 + lean, center_y + 18)],
        (77, 169, 194, alpha),
        4,
    )
    polygon(
        draw,
        [(172 + lean, center_y - 2), (214 + lean, center_y - 25 + wing),
         (199 + lean, center_y + 15), (165 + lean, center_y + 18)],
        (77, 169, 194, alpha),
        4,
    )
    ellipse(draw, (83 + lean, center_y - 39, 173 + lean, center_y + 39), (63, 151, 170, alpha))
    rounded(draw, (99 + lean, center_y - 21, 158 + lean, center_y + 18), 17, (111, 207, 215, alpha), 4)
    ellipse(draw, (112 + lean, center_y - 12, 144 + lean, center_y + 12), (35, 55, 64, alpha), 3)
    ellipse(draw, (121 + lean, center_y - 5, 135 + lean, center_y + 7), CYAN, 2)
    stroke(draw, [(103 + lean, center_y + 31), (91 + lean, center_y + 49)], OUTLINE, 10)
    stroke(draw, [(153 + lean, center_y + 31), (165 + lean, center_y + 49)], OUTLINE, 10)
    if state == "hit":
        stroke(draw, [(177, center_y - 42), (200, center_y - 63)], RED, 7)
    if state == "death":
        image = image.rotate(lean, resample=Image.Resampling.BICUBIC, center=(128, 220))
    return image


DRAWERS = {
    "repair": draw_repair,
    "guard": draw_guard,
    "sapper": draw_sapper,
    "scout": draw_scout,
}


def save_entity(entity_id: str, spec: dict) -> None:
    frames_by_state: dict[str, list[Image.Image]] = {}
    drawer = DRAWERS[spec["draw"]]
    for state, count in spec["states"].items():
        state_dir = RUNTIME_ROOT / entity_id / state
        state_dir.mkdir(parents=True, exist_ok=True)
        frames = []
        for index in range(count):
            frame = drawer(state, index, count)
            frame.save(state_dir / f"frame_{index + 1:02d}.png")
            frames.append(frame)
        frames_by_state[state] = frames
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    rows = len(frames_by_state)
    columns = max(len(frames) for frames in frames_by_state.values())
    sheet = Image.new("RGBA", (columns * 128, rows * 128), (245, 248, 239, 255))
    for row, frames in enumerate(frames_by_state.values()):
        for column, frame in enumerate(frames):
            sheet.alpha_composite(
                frame.resize((128, 128), Image.Resampling.LANCZOS),
                (column * 128, row * 128),
            )
    sheet.save(PREVIEW_ROOT / f"{entity_id}_animation_contact_sheet_v01.png")


def main() -> None:
    for entity_id, spec in SPECS.items():
        save_entity(entity_id, spec)
    print(f"Generated {len(SPECS)} Cardfront entity animation sets in {RUNTIME_ROOT}")


if __name__ == "__main__":
    main()
