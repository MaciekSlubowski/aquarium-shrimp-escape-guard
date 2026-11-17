/*
  Aquarium Shrimp Escape Guard
  ----------------------------
  A corner cover for the top rim of an aquarium. It clips onto the back glass
  and the side glass at a corner, and a flat ledge reaches into the tank along
  both glasses, so shrimp (e.g. Amano shrimp) climbing up the glass or the
  filter pipe cannot get over the rim. A U-shaped cutout fits around the
  filter pipe (inlet or outlet) where it comes over the glass.

  Two guards, one per back corner:
    - Left guard  - for the filter intake pipe.
    - Right guard - for the filter outlet pipe, the mirror image of the left
      one, with an extra hole for two power cables (heater, skimmer) joined
      to the pipe cutout.

  All dimensions in millimetres.
  Coordinate system (left guard, as printed):
  - The corner of the aquarium is at the origin.
  - X runs along the back glass, Y along the side glass.
  - The inside of the tank is towards +Y (back glass) and +X (side glass).
  - Z = 0 is the top plate, lying on the build plate; the clip walls rise
    from it (they hang down over the glass when the guard is mounted).
  Distances "from the corner" or "from the glass" are measured from the
  inner face of the clip, so changing the glass clearance widens the clip
  outwards and does not move the pipe cutout.

  Usage: choose `part`, render (F6) and export the STL (F7).
  Ready-made STLs for the default dimensions are in the stl/ folder.
  The console prints the main dimensions of each guard.
*/

/* [Part] */
part = "both";              // [left:Left guard (intake), right:Right guard (outlet), both:Both guards]
layout_gap = 10;            // Gap between the guards when part = "both" [mm]

/* [Glass clip] */
glass_thickness = 10;       // Thickness of the aquarium glass [mm]
glass_clearance = 2.3;      // Extra slot width: 0.3 mm fit + 2 mm for print tolerance [mm]
wall_thickness = 2.8;       // Clip walls and top plate [mm]
clip_height = 7;            // How far the clip walls reach down over the glass [mm]

/* [Ledge] */
ledge_width = 40;           // How far the flat ledge reaches into the tank [mm]
loop_width = 10;            // Width of the strap that forms the U around the pipe [mm]

/* [Left guard - intake pipe] */
left_side_arm_length = 40;          // Arm along the side glass, from the back clip [mm]
left_pipe_offset = 28;              // Corner to the pipe cutout, from the side clip [mm]
left_length_after_pipe = 40;        // Back arm past the pipe cutout [mm]
left_pipe_width = 23;               // Width of the pipe cutout along the glass [mm]
left_pipe_protrusion = 28;          // How far the pipe elbow reaches into the tank [mm]

/* [Right guard - outlet pipe] */
right_side_arm_length = 40;         // Arm along the side glass, from the back clip [mm]
// Corner to the pipe cutout, from the side clip [mm].
// 42.1 + 17.9 mm clip = 60 mm from the outer corner (see the console).
right_pipe_offset = 42.1;
right_length_after_pipe = 40;       // Back arm past the pipe cutout [mm]
right_pipe_width = 23;              // Width of the pipe cutout along the glass [mm]
right_pipe_protrusion = 28;         // How far the pipe elbow reaches into the tank [mm]

/* [Right guard - cable hole] */
right_cable_hole = true;            // Hole for two 2-core power cables (heater, skimmer)
right_cable_side = "before";        // [before:Between corner and pipe, after:Past the pipe]
right_cable_width = 8;              // Size of the hole along the glass [mm]
right_cable_depth = 12;             // Size of the hole into the tank [mm]
right_cable_gap = 2;                // Distance from the hole to the pipe cutout [mm]
right_cable_offset = 0;             // Distance from the inner clip wall (0 = touching) [mm]
right_cable_merge = true;           // Join the hole to the pipe cutout (one opening)

/* [Quality] */
$fn = 64;

/* [Hidden] */
eps = 0.1;                  // Overlap for clean boolean cuts

// ============================================================================
// DERIVED VALUES (shared by both guards)
// ============================================================================

slot_width  = glass_thickness + glass_clearance;    // Glass slot
clip_width  = wall_thickness + slot_width + wall_thickness;
clip_total  = wall_thickness + clip_height;         // Clip height incl. top plate
ledge_total = clip_width + ledge_width;             // Clip + ledge
glass_inner = wall_thickness + slot_width;          // Inner face of the glass slot

// Length of the back arm (along X)
function guard_length(pipe_offset, pipe_width, length_after_pipe) =
    clip_width + pipe_offset + pipe_width + length_after_pipe;

// Depth of the guard (along Y), used to lay out both guards
function guard_depth(side_arm_length, pipe_protrusion) =
    max(clip_width + side_arm_length, ledge_total,
        clip_width + pipe_protrusion + loop_width);

// ============================================================================
// INPUT CHECKS
// ============================================================================

assert(glass_clearance >= 0, "glass_clearance must not be negative");
assert(right_cable_side == "before" || right_cable_side == "after",
       "right_cable_side must be \"before\" or \"after\"");
assert(right_cable_width > 0 && right_cable_depth > 0,
       "The cable hole needs a positive width and depth");

// ============================================================================
// MODULES
// ============================================================================

// Stadium-shaped cable hole (fully rounded ends) through the top plate, next
// to the inner clip wall. The clip over the glass stays intact: the cables run
// over the top of the guard and drop into the tank through the hole.
// join_x (optional) = edge of the pipe cutout; the hole is then joined to it by
// a strip of the full hole depth, forming one opening.
module cable_hole_cut(x0, y0, width, depth, join_x = undef) {
    r  = min(width, depth) / 2;
    cx = x0 + width / 2;
    hull() {
        for (p = [[x0 + r, y0 + r], [x0 + width - r, y0 + depth - r]])
            translate([p[0], p[1], -1])
                cylinder(r = r, h = wall_thickness + 2);
        if (!is_undef(join_x))
            translate([min(cx, join_x) - eps, y0, -1])
                cube([abs(join_x - cx) + 2 * eps, depth, wall_thickness + 2]);
    }
}

// One corner guard in the left-hand orientation.
// cable = undef for no cable hole, or
//         [width, depth, gap, side, offset, merge] (see the right guard).
module corner_guard(side_arm_length, pipe_offset, length_after_pipe,
                    pipe_width, pipe_protrusion, cable = undef) {
    side_len  = clip_width + side_arm_length;                 // Side arm (Y)
    back_len  = guard_length(pipe_offset, pipe_width, length_after_pipe);
    pipe_x0   = clip_width + pipe_offset;                     // Pipe cutout start
    pipe_x1   = pipe_x0 + pipe_width;                         // Pipe cutout end
    pipe_cx   = pipe_x0 + pipe_width / 2;                     // Pipe cutout centre
    u_cy      = clip_width + pipe_protrusion - pipe_width / 2; // Centre of the U end

    has_cable = !is_undef(cable);
    cable_x0  = !has_cable ? 0
              : cable[3] == "before" ? pipe_x0 - cable[2] - cable[0]
              :                        pipe_x1 + cable[2];
    cable_y0  = has_cable ? clip_width + cable[4] : 0;

    if (has_cable) {
        assert(cable_x0 >= clip_width + 3 && cable_x0 + cable[0] <= back_len - 3,
               "The cable hole does not fit in the back arm - change its side or size");
        assert(cable_y0 + cable[1] <= ledge_total - 3,
               "The cable hole reaches past the ledge - reduce its depth or offset");
    }

    difference() {
        union() {
            // A. Top plate with the ledge (Z = 0 .. wall_thickness)
            cube([ledge_total, side_len, wall_thickness]);    // Side arm
            cube([back_len, ledge_total, wall_thickness]);    // Back arm

            // U-shaped loop around the pipe, merged into the ledge
            hull() {
                translate([pipe_x0 - loop_width, clip_width - wall_thickness, 0])
                    cube([pipe_width + 2 * loop_width, ledge_width + wall_thickness,
                          wall_thickness]);
                translate([pipe_cx, u_cy, 0])
                    cylinder(d = pipe_width + 2 * loop_width, h = wall_thickness);
            }

            // B. Solid clip blocks (the glass slot is cut below)
            cube([clip_width, side_len, clip_total]);         // Side arm
            cube([back_len, clip_width, clip_total]);         // Back arm
        }

        // C. Continuous L-shaped glass slot, open in the corner
        translate([wall_thickness, wall_thickness, wall_thickness]) {
            cube([slot_width, side_len, clip_total]);
            cube([back_len, slot_width, clip_total]);
        }

        // D. Pipe cutout in the ledge, from the glass to the end of the U
        hull() {
            translate([pipe_x0, glass_inner - eps, -1])
                cube([pipe_width, wall_thickness + 1, wall_thickness + 2]);
            translate([pipe_cx, u_cy, -1])
                cylinder(d = pipe_width, h = wall_thickness + 2);
        }

        // E. Pipe passage over the glass (removes both clip walls there)
        translate([pipe_x0, -1, -1])
            cube([pipe_width, 1 + clip_width + eps, clip_total + 2]);

        // F. Cable hole (optional)
        if (has_cable)
            cable_hole_cut(cable_x0, cable_y0, cable[0], cable[1],
                           join_x = !cable[5]            ? undef
                                  : cable[3] == "before" ? pipe_x0
                                  :                        pipe_x1);
    }
}

module left_guard() {
    corner_guard(left_side_arm_length, left_pipe_offset, left_length_after_pipe,
                 left_pipe_width, left_pipe_protrusion);
}

// Mirror image of the left guard, moved back to X >= 0
module right_guard() {
    cable = right_cable_hole
          ? [right_cable_width, right_cable_depth, right_cable_gap,
             right_cable_side, right_cable_offset, right_cable_merge]
          : undef;
    translate([guard_length(right_pipe_offset, right_pipe_width,
                            right_length_after_pipe), 0, 0])
        mirror([1, 0, 0])
            corner_guard(right_side_arm_length, right_pipe_offset,
                         right_length_after_pipe, right_pipe_width,
                         right_pipe_protrusion, cable);
}

// ============================================================================
// CONSOLE REPORT
// ============================================================================

module report(name, side_arm_length, pipe_offset, length_after_pipe,
              pipe_width, pipe_protrusion) {
    echo(str(name, ": ",
             guard_length(pipe_offset, pipe_width, length_after_pipe), " x ",
             guard_depth(side_arm_length, pipe_protrusion), " x ",
             clip_total, " mm, outer corner to pipe cutout = ",
             clip_width + pipe_offset, " mm"));
}

echo(str("Glass slot = ", slot_width, " mm, clip width = ", clip_width, " mm"));
if (part != "right")
    report("Left guard", left_side_arm_length, left_pipe_offset,
           left_length_after_pipe, left_pipe_width, left_pipe_protrusion);
if (part != "left")
    report("Right guard", right_side_arm_length, right_pipe_offset,
           right_length_after_pipe, right_pipe_width, right_pipe_protrusion);

// ============================================================================
// RENDER
// ============================================================================

if (part == "left") {
    left_guard();
} else if (part == "right") {
    right_guard();
} else {
    left_guard();
    translate([0, guard_depth(left_side_arm_length, left_pipe_protrusion)
                  + layout_gap, 0])
        right_guard();
}
