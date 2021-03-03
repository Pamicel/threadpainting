import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

int NUM_PARTICLES = 10;
float STRENGTH = .004;
int SEED = 8;

int NUM_COLOR_TRAILS = 5;

ToxiColorTrail[] colorTrails = new ToxiColorTrail[NUM_COLOR_TRAILS];

Vec2D randomPosition(int wid, int hei) {
  return new Vec2D(floor(random(0, wid + 1)), floor(random(0, hei + 1)));
}

ToxiColorTrail RandomToxiColorTrail(
  VerletPhysics2D physics,
  int wid,
  int hei
) {
  int numStages = floor(random(2, 5));
  float[] speeds = new float[numStages];
  Vec2D[] headPositions = new Vec2D[numStages + 1];
  Vec2D[] tailPositions = new Vec2D[numStages + 1];

  for (int i = 0; i < numStages; i++) {
    if (i < numStages) {
      speeds[i] = random(1, 6);
    }
    headPositions[i] = randomPosition(wid, hei);
    tailPositions[i] = randomPosition(wid, hei);
  }

  headPositions[numStages] = new Vec2D(floor(random(-100, 0)), floor(random(0, hei + 1)));
  tailPositions[numStages] = new Vec2D(floor(random(-100, 0)), floor(random(0, hei + 1)));


  return new ToxiColorTrail(
    physics,
    speeds,
    headPositions,
    tailPositions,
    floor(random(4, 21)), // Links
    random(.5, 1), // Mass
    random(.1), // Strength
    new Vec3D(
      .1 * TWO_PI,
      .2 * TWO_PI,
      .3 * TWO_PI
    )
  );
}

void setup() {
  size(1600, 900);
  smooth();
  randomSeed(SEED);
  background(255);
  noStroke();

  physics = new VerletPhysics2D();

  for( int i = 0; i < NUM_COLOR_TRAILS; i++) {
    colorTrails[i] = RandomToxiColorTrail(physics, width, height);
  }
}

void draw() {
  physics.update();
  float omega = .8 * TWO_PI;
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    colorTrails[i].update();
    colorTrails[i].colorString.display(0.02, omega);
    colorTrails[i].colorString.displayOneInTwo(0.02, omega);
  }
  //  saveFrame("out/screen-####-seed-" + SEED + ".tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame("out/screen-####-seed-" + SEED + ".tif");
  }
}
