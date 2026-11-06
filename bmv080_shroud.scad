// BMV080 sensor shroud for the Sensr Air PCB (air-stcc4 v0.4.0)
// https://github.com/romkey/sensr-air
//
// A small cage that bridges the BMV080 sensor head and fastens to the two
// 1.3 mm plated holes on either side of it. It locates the LGA package in
// X/Y, keeps it from lifting off the board, and leaves the lens and the
// laser path completely open. The rim stands slightly proud of the lens so
// a finger or a tabletop touches plastic first.
//
// Coordinate system (all mm):
//   origin = midpoint between the two shroud holes  = KiCad (48.5, 27.0)
//   +X     = toward the tip of the flex (away from the FPC connector)
//   +Y     = toward the top edge of the board (KiCad -Y)
//   Z = 0  = top surface of the PCB
//
// Printing: 0.1-0.12 mm layers, 0.4 mm nozzle (0.25 is nicer).
//   mount = "screw": print as modelled, PCB face on the bed. The 4.9 mm
//                    ceiling over the sensor is a short bridge, no supports.
//   mount = "peg":   printed upside down (done automatically by print_layout)
//                    so the pegs stand upright.

/* [Mounting] */
// "screw": through holes for M1.2 screws. "peg": printed pegs to glue or heat-stake.
mount = "screw"; // [screw, peg]
// Screw hole in the ears. 1.4 = M1.2 clearance (nut on the back of the PCB). Use ~1.0 to self-tap an M1.2 screw driven from the back.
screw_hole_d = 1.4;
// Peg diameter for the 1.3 mm PCB holes.
peg_d = 1.15;
// How far the pegs stick out of the back of the PCB.
peg_protrusion = 0.8;
// Screw head diameter; the tall centre section stops short of the ears to leave room for it.
screw_head_d = 2.6;

/* [PCB - from air-stcc4.kicad_pcb 0.4.0] */
hole_spacing = 9.0;      // vias at (48.5, 22.5) and (48.5, 31.5)
pcb_t = 1.6;
// LGA package centre relative to the hole midpoint (silkscreen outline centre 48.625, 27.124).
lga_center = [0.125, -0.124];

/* [BMV080 - from datasheet BST-BMV080-DS000-12, Fig. 7] */
flex_w = 4.4;            // flex width at the sensor head
flex_t = 0.225;          // flex thickness under the LGA
lga_len = 3.0;           // LGA along the flex
lga_w = 4.3;             // LGA across the flex
lga_shoulder_h = 1.22;   // tallest part of the LGA body, above the flex
lens_top_h = 2.78;       // top of the lens, above the flex
lens_d = 2.58;           // +/- 0.15
// Lens centre measured from the LGA edge (1.648 in the datasheet).
lens_edge_offset = 1.648;
// Which side of the flex centreline the lens sits on. -1 matches the datasheet with the flex contacts facing the PCB. Flip to 1 if your lens is on the other side.
lens_side = -1; // [-1, 1]
// Thermal tape / pad between the flex and the PCB, if you use one.
tape_t = 0.0;

/* [Fit] */
// Side clearance between the flex and the pocket walls.
xy_clear = 0.25;
// Gap between the top of the LGA and the ceiling. The sensor is captured, not clamped (max 3 N allowed on the package).
z_clear = 0.10;
// Radial clearance around the lens.
lens_clear = 0.40;
// How far the rim stands above the top of the lens.
lens_guard = 0.30;

/* [Body] */
ear_d = 4.2;
// Height of the screw ears (screw mode). Pegged ears are always full height.
ear_h = 2.2;
// Wall beyond the tip of the flex.
tip_wall = 1.0;
// How far the body reaches back over the flex, measured from the hole line.
back_reach = 2.6;
// 45 degree chamfer around the top of the lens opening.
lens_chamfer = 0.5;

/* [View] */
// Show the PCB and sensor as a transparent reference (never exported).
show_ghost = false;
// Orient the part for printing (only changes peg mode).
print_layout = true;

/* [Hidden] */
$fn = 64;
eps = 0.01;

ceiling_z = tape_t + flex_t + lga_shoulder_h + z_clear;
top_z     = tape_t + flex_t + lens_top_h + lens_guard;
pocket_w  = flex_w + 2 * xy_clear;
tip_x     = lga_center[0] + lga_len / 2 + xy_clear;   // inside face beyond the flex tip
body_x0   = -back_reach;
body_x1   = tip_x + tip_wall;
lens_pos  = [lga_center[0],
             lga_center[1] + lens_side * (lga_w / 2 - lens_edge_offset)];
lens_hole_d = lens_d + 0.15 + 2 * lens_clear;
ear_height  = mount == "peg" ? top_z : ear_h;
// half-length of the full-height centre section
tower_half  = mount == "peg" ? hole_spacing / 2
                             : hole_spacing / 2 - screw_head_d / 2 - 0.2;

module ears_2d() {
    for (s = [-1, 1]) translate([0, s * hole_spacing / 2]) circle(d = ear_d);
}

module body() {
    // central bar that bridges the sensor
    translate([body_x0, -tower_half, 0])
        cube([body_x1 - body_x0, 2 * tower_half, top_z]);
    translate([body_x0, -hole_spacing / 2, 0])
        cube([body_x1 - body_x0, hole_spacing, ear_height]);
    // screw / peg ears, blended into the bar
    linear_extrude(ear_height) hull() ears_2d();
}

module pocket() {
    // channel for the flex + LGA, open toward the connector
    translate([body_x0 - 1, lga_center[1] - pocket_w / 2, -eps])
        cube([tip_x - body_x0 + 1, pocket_w, ceiling_z + eps]);
}

module lens_opening() {
    translate([lens_pos[0], lens_pos[1], 0]) {
        cylinder(d = lens_hole_d, h = top_z + 1);
        translate([0, 0, top_z - lens_chamfer])
            cylinder(d1 = lens_hole_d, d2 = lens_hole_d + 2 * lens_chamfer + 2 * eps,
                     h = lens_chamfer + eps);
    }
}

module shroud() {
    difference() {
        body();
        pocket();
        lens_opening();
        if (mount == "screw")
            for (s = [-1, 1]) translate([0, s * hole_spacing / 2, -1])
                cylinder(d = screw_hole_d, h = top_z + 2);
    }
    if (mount == "peg")
        for (s = [-1, 1]) translate([0, s * hole_spacing / 2, -(pcb_t + peg_protrusion)])
            cylinder(d = peg_d, h = pcb_t + peg_protrusion + eps);
}

// Reference geometry: PCB patch, flex, LGA and lens.
module ghost() {
    color("green", 0.4) difference() {
        translate([-20, -8, -pcb_t]) cube([28, 15, pcb_t]);
        for (s = [-1, 1]) translate([0, s * hole_spacing / 2, -pcb_t - 1])
            cylinder(d = 1.3, h = pcb_t + 2);
    }
    tip = lga_center[0] + lga_len / 2;
    color("orange", 0.6)
        translate([tip - 20, lga_center[1] - flex_w / 2, tape_t]) cube([20, flex_w, flex_t]);
    color("silver", 0.8)
        translate([tip - lga_len, lga_center[1] - lga_w / 2, tape_t + flex_t])
            cube([lga_len, lga_w, 0.94]);
    color("dimgray", 0.8)   // raised shoulder, on the side away from the lens
        translate([tip - lga_len, lga_center[1] - lens_side * lga_w / 2
                   - (lens_side < 0 ? 0.759 : 0), tape_t + flex_t])
            cube([lga_len, 0.759, lga_shoulder_h]);
    color("white", 0.9)
        translate([lens_pos[0], lens_pos[1], tape_t + flex_t])
            cylinder(d = lens_d, h = lens_top_h);
}

if (show_ghost) {
    shroud();
    ghost();
} else if (print_layout && mount == "peg") {
    translate([0, 0, top_z]) rotate([180, 0, 0]) shroud();
} else {
    shroud();
}

echo(str("ceiling ", ceiling_z, " mm, top ", top_z, " mm, footprint ",
         body_x1 - body_x0, " x ", hole_spacing + ear_d, " mm"));
