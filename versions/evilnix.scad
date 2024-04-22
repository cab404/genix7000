// SPDX-License-Identifier: GPL-3.0-or-later

// Well, openscad fucks up its svg export, so you need _something_ in the frame
circle(r = 0.0001);

// === Nix logo specification
// number of lambdas. doesn't really work if changed in this model.
num = 5;


// rnot = 1;
// ran = 120;
// sn = sin($t * rnot * 360);
// rot = (sn + $t * rnot) * ran;
rot = sin($t * 360) * 30 - 120;

res = (cos(($t * 360)) + 1) / 2;
// res = 0;
// Central aperture diameter, in units. It does produce nice effects if animated.
aperture = 2 + -1 * res;

// lambda height in units. fun to play with
length = 5;// + -4 * res;

// Clipping polygon diameter, in units
clipr = 20;// + -8 * res;


// === Some calculated core stuff

// lambda thickness, also a segment size. Should affects nothing except size.
unit = 25;

// The angle™
th = 360 / num / 2;

// Unit value of Y when mapped to coordinate space with angle between axes of "th"
tunit = tan(th)*unit;

// === Rendering props

// Shrinkage for each of lambdas. Basically control inverse "font weight"
gaps = 4;
// colors to use
colors = ["#cc0000"];

// inverse clipping order
invclip = false;
show_hexgrid = false;
show_full = true;

printed_version = "none"; // ["none", "one piece", "module"]

printed_h = 30;
circle_r = 43;
circle_t = 6;
circle_h = 6;
pin_l = 4*tunit;
pin_r = 3;

// Pin/hole size ratio, to account for plastic heat deformation
hole_ratio = 1.07;

// copied from <MCAD/regular_shapes.scad> so customizer will work on thingiverse
module regular_polygon(sides, radius)
{
    function dia(r) = sqrt(pow(r*2,2)/2);  //sqrt((r*2^2)/2) if only we had an exponention op
    angles=[ for (i = [0:sides-1]) i*(360/sides) ];
    coords=[ for (th=angles) [radius*cos(th), radius*sin(th)] ];
    polygon(coords);
}


module hexgrid(thickness=1.5) union() {
    // Yes you can go lower for hexagonal grids.
    for (i=[0:num-1]) {
        rotate(i*th*2+th)
        for (i=[-clipr:clipr]) {
            translate([i*unit/2,0])
            square([thickness, clipr * unit * 2],center=true);
        };
    };
}


// draw a ~perfect~ 2D lambda
module lambda() {
    intersection(){
        union() {
            // Lambda arm
            rotate(-th)
            translate([0,-tunit*length])
            square([unit,length*tunit*2], center=true);
            // Lambda bar
            rotate(th)
            square([unit,tunit*(length*2 + 1)], center=true);
        }
        // Cutting top and bottom of squares to be left with a perfect lambda
        // Lambda *almost* scales uniformly.
        // We just need to account for corner triangles, making it + 2 wider.
        square([tunit*(length + 2), unit*length], center=true);
    }
}

// Subtracts a rotated child from itself
module diff(nextangle, debug=false) {
    difference() {
        children();
        rotate(invclip ? nextangle : -nextangle) children();
    }
}

module clipper(){
    // that's not as easy to autotune as it would seem
    intersection() {
        regular_polygon(num, clipr * tunit);
        children();
    }
}

module move_to_lambda_origin(index) {

}

module placed_lambda() {
    offset(delta = -gaps)
    clipper()
    // cutting it up with the same lambda at the next place
    diff(360/num)
    // translation to endpoint
    translate([tunit * -aperture, unit * -aperture])
    // initial in-place rotation
    rotate(rot)
    lambda();
}

module render_logo(segments=[0:num-1]) {
    for (r=segments)
    // color it with next color in array
        color(colors[r % len(colors)])
        rotate(th*2*r)
        placed_lambda();
}

module make_pin(scl = 1, r = pin_r) {

    // Only rescale crossection, so length doesn't change
    scale([1,scl,scl])

    translate([tunit * -aperture, unit * -aperture])
    rotate(th)
    // extrude pin from the center to the side of a limbda
    translate([0,pin_l/2,0])
    rotate([90,45])
    cube([r * 2, r * 2, pin_l], center=true);
    //cylinder(50, r, r, center=true);
}

module render_module() {
    render()
    difference() {
        union() {
            make_pin(1);
            linear_extrude(printed_h, center=true)

            clipper()
            placed_lambda();
        }
        for (i=[1:num-2]) {
        rotate((invclip ? -i : i) * 360/num) make_pin(hole_ratio);
        }
        // ensuring that hole is slightly larger

        // usually not needed, but you
        // can actually thread stuff thru two next lambdas
        // rotate((invclip ? -2 : 2) * 360/num) make_pin(hole_ratio);
    }
}

// Actual rendering
module intr() {
    rotate(15 )
    difference() {
        render_logo();
        if (show_hexgrid)
            hexgrid();
    };
};
if (printed_version == "none") {
    intr();
    color("#cc0000")
    offset(delta = -gaps)
    difference() {
        circle(r = 90);
        circle(r = 65);
        intr();
    }

}
if (printed_version == "module") {
    difference() {
        render_module();
        if (show_hexgrid)
            translate([0,0,printed_h/2-1])
            linear_extrude(2)
            hexgrid();
    }
    if (show_full)
        translate([0,0, printed_h / -2])
        color("#ff000033")
        render_logo();

}

if (printed_version == "one piece")
union() {

    linear_extrude(circle_h, center=true)

    difference() {
        circle(circle_r);
        circle(circle_r - circle_t);
    }

    difference() {
        linear_extrude(printed_h, center=true)
        render_logo();

        if (show_hexgrid)
            translate([0,0,printed_h/2-1])
            linear_extrude(1)
            hexgrid();
    }
};
