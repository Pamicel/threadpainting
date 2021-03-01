import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

int NUM_PARTICLES = 10;
float STRENGTH = .004;

float[] speeds = new float[] { 1, 2, .6 };

Vec2D[] headPositions = new Vec2D[] {
  new Vec2D(450, 250), // stage one start
  new Vec2D(700, 200), // stage two start
  new Vec2D(900, 400), // stage three start
  new Vec2D(1150, 400) // end
};

Vec2D[] tailPositions = new Vec2D[] {
  new Vec2D(450, 350), // stage one start
  new Vec2D(700, 350), // stage two start
  new Vec2D(750, 500), // stage three start
  new Vec2D(1150, 500) // end
};

ToxiColorTrail[] colorTrails = new ToxiColorTrail[4];

void setup() {
  size(1600, 900);
  smooth();
  background(255);
  noStroke();

  physics = new VerletPhysics2D();
  colorTrails[0] = new ToxiColorTrail(
    physics,
    new float[] { 1, 2, .6 },
    new Vec2D[] {
      new Vec2D(450, 250), // stage one start
      new Vec2D(700, 200), // stage two start
      new Vec2D(900, 400), // stage three start
      new Vec2D(1150, 400) // end
    },
    tailPositions = new Vec2D[] {
      new Vec2D(450, 350), // stage one start
      new Vec2D(700, 350), // stage two start
      new Vec2D(750, 500), // stage three start
      new Vec2D(1150, 500) // end
    },
    9, // Links
    1, // Mass
    .004, // Strength
    new Vec3D(
      .1 * TWO_PI,
      .2 * TWO_PI,
      .3 * TWO_PI
    )
  );
  colorTrails[1] = new ToxiColorTrail(
    physics,
    new float[] { 1, 2 },
    new Vec2D[] {
      new Vec2D(700, 200),
      new Vec2D(1000, 200),
      new Vec2D(1100, 0)
    },
    tailPositions = new Vec2D[] {
      new Vec2D(900, 400),
      new Vec2D(1100, 350),
      new Vec2D(900, 0)
    },
    12, // Links
    1, // Mass
    .001, // Strength
    new Vec3D(
      .1 * TWO_PI,
      .2 * TWO_PI,
      .3 * TWO_PI
    )
  );
  colorTrails[2] = new ToxiColorTrail(
    physics,
    new float[] { 1, 2, 4 },
    new Vec2D[] {
      new Vec2D(100, 200),
      new Vec2D(250, 500),
      new Vec2D(450, 350),
      new Vec2D(600, 650)
    },
    tailPositions = new Vec2D[] {
      new Vec2D(450, 150),
      new Vec2D(450, 500),
      new Vec2D(700, 350),
      new Vec2D(700, 650)
    },
    20, // Links
    1, // Mass
    .01, // Strength
    new Vec3D(
      .1 * TWO_PI,
      .2 * TWO_PI,
      .3 * TWO_PI
    )
  );
  colorTrails[3] = new ToxiColorTrail(
    physics,
    new float[] { 4, 4, 2 },
    new Vec2D[] {
      new Vec2D(850, 500),
      new Vec2D(850, 550),
      new Vec2D(850, 550),
      new Vec2D(0, 700)
    },
    tailPositions = new Vec2D[] {
      new Vec2D(1400, 500),
      new Vec2D(1150, 550),
      new Vec2D(850, 650),
      new Vec2D(0, 900)
    },
    20, // Links
    1, // Mass
    .02, // Strength
    new Vec3D(
      .3 * TWO_PI,
      .2 * TWO_PI,
      .1 * TWO_PI
    )
  );
}

void draw() {
  physics.update();
  colorTrails[0].update();
  colorTrails[1].update();
  colorTrails[2].update();
  colorTrails[3].update();

  float omega = .8 * TWO_PI;
  colorTrails[0].colorString.display(0.02, omega);
  colorTrails[0].colorString.displayOneInTwo(0.02, omega);
  colorTrails[1].colorString.display(0.05, omega);
  colorTrails[1].colorString.displayOneInTwo(0.05, omega + .2);
  colorTrails[2].colorString.display(0.05, omega);
  colorTrails[2].colorString.displayOneInTwo(0.05, omega + .2);
  colorTrails[3].colorString.display(0.1, omega + 1);
  colorTrails[3].colorString.displayOneInTwo(0.1, omega + 1);
  // colorTrail.colorString.displaySkeleton();
  // colorTrail.stages[colorTrail.getCurrentStage()].displayDebug();

  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
