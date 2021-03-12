import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

PGraphics layer1, layer2;

int SEED = 3;
int NUM_COLOR_TRAILS = 10;
int NUM_COLOR_TRAILS_LAYER_2 = 4;

ToxiColorTrail[] colorTrailsLayer1 = new ToxiColorTrail[NUM_COLOR_TRAILS];
ToxiColorTrail[] colorTrailsLayer2 = new ToxiColorTrail[NUM_COLOR_TRAILS_LAYER_2];

class LayerVariables {
  LayerVariables() {}
  public float[] rgbK;
  public float[] rgbIntensity;
  public float[] rgbOffset;
  public float omega;
}

LayerVariables layer1Vars = new LayerVariables();
LayerVariables layer2Vars = new LayerVariables();

Vec2D randomPosition(Rect rectangle) {
  int xmin = (int)rectangle.x;
  int xmax = (int)(rectangle.x + rectangle.width);
  int ymin = (int)rectangle.y;
  int ymax = (int)(rectangle.y + rectangle.height);

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
  Rect rectangle,
  int numStages,
  float minSpeed,
  float maxSpeed,
  int minRadius,
  int maxRadius,
  int links,
  float mass,
  float strength
) {
  float[] speeds = new float[numStages];
  ColorTrailTarget[] targets = new ColorTrailTarget[numStages + 1];

  for (int i = 0; i < numStages + 1; i++) {
    if (i < numStages) {
      speeds[i] = random(minSpeed, maxSpeed);
    }

    targets[i] = new ColorTrailTarget(
      randomPosition(rectangle),
      floor(random(minRadius, maxRadius)),
      // 20,
      PI
    );
  }


  return new ToxiColorTrail(
    physics,
    speeds,
    targets,
    links, // Links
    mass, // Mass
    strength // Strength
  );
}

void setup() {
  size(900, 900);
  smooth();
  randomSeed(SEED);

  layer1Vars.rgbK = new float[] { 0, 0, -0.05 };
  layer1Vars.rgbIntensity = new float[] { 0, 0.2, 1 };
  layer1Vars.rgbOffset = new float[]{ 0, 0, 8.5 };
  layer1Vars.omega = .1;

  layer2Vars.rgbK = new float[] { 0, 0.05, 0.03 };
  layer2Vars.rgbIntensity = new float[] { 1, 0.4, 1 };
  layer2Vars.rgbOffset = new float[]{ 0.1, 0.2, 5.6 };
  layer2Vars.omega = .1;

  layer1 = createGraphics(width, height);
  layer2 = createGraphics(width, height);

  physics = new VerletPhysics2D();

  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    int[] pad = new int[] {200, 100};
    colorTrailsLayer1[i] = randomToxiColorTrail(
      physics,
      new Rect(width / 4, height / 4, width / 2, height / 2),
      3,
      2, 2,
      100, 150,
      4,
      1,
      .001
    );
  }

  for(int i = 0; i < NUM_COLOR_TRAILS_LAYER_2; i++) {
    int[] pad = new int[] {200, 100};
    colorTrailsLayer2[i] = randomToxiColorTrail(
      physics,
      new Rect(width / 4, height / 4, width / 2, height / 2),
      10,
      4, 5,
      20, 50,
      4,
      .1,
      .01
    );
  }
}

void draw() {

  background(255);

  image(layer2, 0, 0);
  image(layer1, width / 6, height / 6, 2 * width / 3, 2 * height / 3);
  //image(layer2, 0, 0);
  // colorTrailsLayer1[4].update();
  // colorTrailsLayer1[4].colorString.displaySkeleton();
  // colorTrailsLayer1[4].colorString.debugHead();
  // colorTrailsLayer1[4].colorString.debugTail();
  // if (!colorTrailsLayer1[4].finished()) {
  //   colorTrailsLayer1[4].stages[colorTrailsLayer1[4].getCurrentStage()].displayDebug();
  // }
  // saveFrame("out/screen-####.tif");
  noLoop();
}

void keyPressed() {
  if (key == ' ') {
    saveFrame("out/screen-####.tif");
  }
}

void mousePressed() {
  int iterations = 1000;
  for (; iterations > 0; iterations--) {
    physics.update();
    layer2.beginDraw();
    for(int i = 0; i < NUM_COLOR_TRAILS_LAYER_2; i++) {
      if (colorTrailsLayer2[i].finished()) {
        continue;
      }
      colorTrailsLayer2[i].update();
      colorTrailsLayer2[i].colorString.displayStraight(
        layer2,
        layer2Vars.rgbK,
        layer2Vars.rgbIntensity,
        layer2Vars.rgbOffset,
        layer2Vars.omega
      );
      colorTrailsLayer2[i].colorString.displayOneInTwo(
        layer2,
        layer2Vars.rgbK,
        layer2Vars.rgbIntensity,
        layer2Vars.rgbOffset,
        layer2Vars.omega
      );
    }
    layer2.endDraw();

    layer1.beginDraw();
    for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
      if (colorTrailsLayer1[i].finished()) {
        continue;
      }
      colorTrailsLayer1[i].update();

      colorTrailsLayer1[i].colorString.displayStraight(
        layer1,
        layer1Vars.rgbK,
        layer1Vars.rgbIntensity,
        layer1Vars.rgbOffset,
        layer1Vars.omega + (HALF_PI * i / (2 * NUM_COLOR_TRAILS))
      );
      colorTrailsLayer1[i].colorString.displayOneInTwo(
        layer1,
        layer1Vars.rgbK,
        layer1Vars.rgbIntensity,
        layer1Vars.rgbOffset,
        layer1Vars.omega + (HALF_PI * i / (2 * NUM_COLOR_TRAILS))
      );
    }
    layer1.endDraw();
  }
  loop();
}
