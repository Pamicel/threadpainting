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

ToxiColorTrail colorTrail;

void setup() {
  size(1600, 900);
  smooth();
  physics = new VerletPhysics2D();
  colorTrail = new ToxiColorTrail(
      physics,
      speeds,
      headPositions,
      tailPositions,
      NUM_PARTICLES - 1,
      1,
      STRENGTH
  );
  background(0);
  noStroke();
}

void draw() {
  physics.update();
  colorTrail.update();

  float omega = .8 * TWO_PI;
  colorTrail.colorString.display(0.02, omega);
  colorTrail.colorString.displayOneInTwo(0.02, omega);
  // colorTrail.colorString.displaySkeleton();
  // colorTrail.stages[colorTrail.getCurrentStage()].displayDebug();

  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
