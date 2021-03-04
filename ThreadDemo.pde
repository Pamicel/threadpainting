import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

int SEED = 1;
int NUM_COLOR_TRAILS = 20;

ToxiColorTrail[] colorTrails = new ToxiColorTrail[NUM_COLOR_TRAILS];

Vec2D randomPosition(int xmin, int xmax, int ymin, int ymax) {
  return new Vec2D(floor(random(xmin, xmax + 1)), floor(random(ymin, ymax + 1)));
}

class ColorTrailTarget {
  public Vec2D headPosition;
  public Vec2D tailPosition;

  ColorTrailTarget(
    Vec2D position,
    int radius,
    float angle
  ) {
    Vec2D radiusVector = new Vec2D(radius * cos(angle), radius * sin(angle));
    this.headPosition = position.copy().add(radiusVector);
    this.tailPosition = position.copy().sub(radiusVector);
  }
}

ToxiColorTrail randomToxiColorTrail(
  VerletPhysics2D physics,
  int wid,
  int hei
) {
  int numStages = 5;
  float[] speeds = new float[numStages];
  ColorTrailTarget[] targets = new ColorTrailTarget[numStages + 1];

  for (int i = 0; i < numStages + 1; i++) {
    if (i < numStages) {
      // speeds[i] = random(1, 3);
      speeds[i] = 2;
    }

    targets[i] = new ColorTrailTarget(
      randomPosition(200, wid - 200, 300, hei - 300),
      floor(random(20, 100)),
      HALF_PI
    );
  }


  return new ToxiColorTrail(
    physics,
    speeds,
    targets,
    6, // Links
    1, // Mass
    .001, // Strength
    new Vec3D(
      .1,
      -3.2,
      1.5
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
    colorTrails[i] = randomToxiColorTrail(physics, width, height);
  }
}

float[] rgbK = new float[] {
  0,
  0.1,
  0.1
};

float[] rgbIntensity = new float[] {
  1,
  1,
  1
};

float omega = .1;

void draw() {
  physics.update();
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrails[i].finished()) {
      continue;
    }
    colorTrails[i].update();
    colorTrails[i].colorString.displayStraight(
      rgbK,
      rgbIntensity,
      omega + i
    );
    colorTrails[i].colorString.displayOneInTwo(
      rgbK,
      rgbIntensity,
      omega + i
    );
  }
  // colorTrails[4].update();
  // colorTrails[4].colorString.displaySkeleton();
  // colorTrails[4].colorString.debugHead();
  // colorTrails[4].colorString.debugTail();
  // if (!colorTrails[4].finished()) {
  //   colorTrails[4].stages[colorTrails[4].getCurrentStage()].displayDebug();
  // }
  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame("out/screen-####.tif");
  }
}
