// SPDX-License-Identifier: GPL-3.0-or-later

// Universal Nix project logo generator!

// number of lambdas
num = 6; // [3:25]

// Offset of lambda
foff = [-24, -42];

// Offset after clipping. Use for gaps.
gaps = [3, -5];

// rotation of each lambda
lrot = 0; // [-180:180]

// lambda arm angle
larm = 30; // [-180:180]

// Clipping ngon radius
clipr = 92; // [0:300]
// Clipping ngon rotation
cliprot = 0;  // [-180:180]

// lambda thickness
thick = 20; // [5:30]

// remove this parameter if you want to update Thingiverse project 
// colors to use
colors = ["#5277c3", "#7caedc"];

// inverse clipping order
invclip = false;

show_full = false;
show_module = false;
show_circle = false;

// copied from <MCAD/regular_shapes.scad> so customizer will work on thingieverse
module regular_polygon(sides, radius)
{
    function dia(r) = sqrt(pow(r*2,2)/2);  //sqrt((r*2^2)/2) if only we had an exponention op
    angles=[ for (i = [0:sides-1]) i*(360/sides) ];
    coords=[ for (th=angles) [radius*cos(th), radius*sin(th)] ];
    polygon(coords);
}

// draw a 2D lambda
module lambda() {
    union() {
        rotate(-larm) translate([0,-25]) square([thick,50], center=true);
        rotate(larm) square([thick,100], center=true);
    }    
}

module debugdiff(debug = false){
    if (!debug)
        difference() { 
            children(0);
            children(1);
        }
    else{
        union() { 
            difference() { 
                children(0);
                children(1);
            };
            children(1);
        }
    }
}
// generates lambda and subtracts next lambda from it
module diff(nextangle, debug=false) {
    debugdiff(debug) {
        children();
        color("red")
        rotate(invclip ? nextangle : -nextangle) children();
    }
}

module clipper(){
    // that's not as easy to autotune as it would seem
    intersection() {
        rotate(cliprot) regular_polygon(num, clipr);
        children();
    }    
}

if (false) {
    rotate([20,0,0])
    translate([-16,-50,-90])
    cube([5,5,50]);

    rotate([37,+19,0])
    translate([+38,-32,-103])
    cube([5,5,88]);

    translate([0,0,-110])
    linear_extrude(10, scale = 0.9)
    square([100,100], center = true);
}

//rotate([70,8,0])
// render the logo!
if (show_full)
color("#ff000022")
union() {

    color("#000000")
    translate([0,0,8])
    linear_extrude(4)
    if (show_circle)
    difference() {
        circle(46);
        circle(40);
    }
 
    // just do that N times
    for (r=[0:num])
    // color it with next color in array
    color(colors[r % len(colors)])
    linear_extrude(20)
    // flatten before coloring
    // final rotation, putting lambda in place
    rotate(360/num*r)
    translate(gaps)
    // clip the edges
    clipper()
    // cutting it up with the same lambda at the next place
    diff(360/num)
    // translation to endpoint
    translate(foff)
    // initial in-place rotation
    rotate(lrot)
    lambda();
}

module make_pin(scl = 1, r = 4) {
    translate(foff + gaps)
    
    rotate(lrot)
    rotate(larm)
    
    translate([+0,30,10])
    
    rotate([90,])
    scale(scl)
    cube([r * 2, r * 2, 50], center=true);
    //cylinder(50, r, r, center=true);
}

if (show_module)
render()
difference() {
    union() {
        make_pin(1);
        
        translate(gaps)
        linear_extrude(20)
        // flatten before coloring
        // final rotation, putting lambda in place
        //rotate(360/num*r)
        // clip the edges
        clipper()
        // cutting it up with the same lambda at the next place
        
        diff(360/num)
        // translation to endpoint
        translate(foff)
        // initial in-place rotation
        rotate(lrot)
        lambda();
    }
    // ensuring that hole is slightly larger
    rotate((invclip ? -1 : 1) * 360/num) make_pin(1.1);
}
//rotate((invclip ? -1 : 1) * 360/num) make_pin(1.1);