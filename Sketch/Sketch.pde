import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

PGraphics layer1;
PGraphics layer2;
PGraphics layer3;

boolean video = false;

int randomInt (int min, int max) {
  // Random int with evenly distributed probabilities
  return floor(random(min, max + 1));
}

int randomInt (int max) {
  return randomInt(0, max);
}

int SEED = 1;
int NUM_COLOR_TRAILS = 20;
int NUM_STEP_SEGMENTS = 50;
Bezier5Path[] beziers = new Bezier5Path[NUM_COLOR_TRAILS];

ToxiColorTrail[] colorTrailsLayer1 = new ToxiColorTrail[NUM_COLOR_TRAILS];
ToxiColorTrail[] colorTrailsLayer2 = new ToxiColorTrail[NUM_COLOR_TRAILS];
ToxiColorTrail[] colorTrailsLayer3 = new ToxiColorTrail[NUM_COLOR_TRAILS];

class LayerVariables {
  LayerVariables() {}
  public float[] rgbK;
  public int[] baseColor;
  public float[] rgbOffset;
  public float omega;
}

LayerVariables layer1Vars = new LayerVariables();
LayerVariables layer2Vars = new LayerVariables();
LayerVariables layer3Vars = new LayerVariables();

Vec2D randomPosition(Rect rectangle) {
  int xmin = (int)rectangle.x;
  int xmax = (int)(rectangle.x + rectangle.width);
  int ymin = (int)rectangle.y;
  int ymax = (int)(rectangle.y + rectangle.height);

  return new Vec2D(randomInt(xmin, xmax), randomInt(ymin, ymax));
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

class Bezier5Path {
  public Vec2D[] path;
  private Vec2D[] controlPoints;
  private int numSteps;

  Bezier5Path(Vec2D[] controlPoints, int numSteps) {
    if (controlPoints.length != 6) {
      throw new Error("Bezier of degree 5 requires 2 end points and 4 control points");
    }
    this.controlPoints = controlPoints;
    this.numSteps = numSteps;
    this.path = new Vec2D[numSteps + 1];

    Vec2D position;
    for (int i = 0; i < numSteps + 1; i++) {
      position = this.getPosition((float)i / numSteps);
      this.path[i] = position;
    }
  }

  Vec2D getPosition (float t) {
    if (t <= 0) {
      return this.controlPoints[0];
    } if (t >= 1) {
      return this.controlPoints[5];
    }

    float factor0 = pow((1 - t), 5);
    float factor1 = 5 * t * pow((1 - t), 4);
    float factor2 = 10 * pow(t, 2) * pow((1 - t), 3);
    float factor3 = 10 * pow(t, 3) * pow((1 - t), 2);
    float factor4 = 5 * pow(t, 4) * (1 - t);
    float factor5 = pow(t, 5);

    float x =
      factor0 * this.controlPoints[0].x
      + factor1 * this.controlPoints[1].x
      + factor2 * this.controlPoints[2].x
      + factor3 * this.controlPoints[3].x
      + factor4 * this.controlPoints[4].x
      + factor5 * this.controlPoints[5].x;

    float y =
      factor0 * this.controlPoints[0].y
      + factor1 * this.controlPoints[1].y
      + factor2 * this.controlPoints[2].y
      + factor3 * this.controlPoints[3].y
      + factor4 * this.controlPoints[4].y
      + factor5 * this.controlPoints[5].y;

    return new Vec2D(x, y);
  }

  void display() {
    for (int i = 0; i < this.numSteps + 1; i++) {
      ellipse(this.path[i].x, this.path[i].y, 8, 8);
    }
  }

  void displayControlPoints() {
    for (int i = 0; i < this.controlPoints.length; i++) {
      ellipse(this.controlPoints[i].x, this.controlPoints[i].y, 30, 30);
    }
  }
}

ToxiColorTrail ToxiColorTrailFromBezier(
  VerletPhysics2D physics,
  Bezier5Path bezier,
  float[] angles,
  float minSpeed,
  float maxSpeed,
  int minRadius,
  int maxRadius,
  int links,
  float mass,
  float strength
) {
  int numSteps = bezier.path.length - 1;
  float[] speeds = new float[numSteps];
  ColorTrailTarget[] targets = new ColorTrailTarget[numSteps + 1];

  for (int i = 0; i < numSteps + 1; i++) {
    if (i < numSteps) {
      speeds[i] = random(minSpeed, maxSpeed);
    }

    targets[i] = new ColorTrailTarget(
      bezier.path[i],
      randomInt(minRadius, maxRadius),
      angles[i]
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

ToxiColorTrail randomToxiColorTrail(
  VerletPhysics2D physics,
  Rect rectangle,
  int numSteps,
  float minSpeed,
  float maxSpeed,
  int minRadius,
  int maxRadius,
  int links,
  float mass,
  float strength
) {
  float[] speeds = new float[numSteps];
  ColorTrailTarget[] targets = new ColorTrailTarget[numSteps + 1];

  for (int i = 0; i < numSteps + 1; i++) {
    if (i < numSteps) {
      speeds[i] = random(minSpeed, maxSpeed);
    }

    targets[i] = new ColorTrailTarget(
      randomPosition(rectangle),
      randomInt(minRadius, maxRadius),
      random(0, TWO_PI)
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

PImage backgroundImage;

void setup() {
  size(900, 900);
  smooth();
  randomSeed(SEED);

  layer1Vars.rgbK =           new float[] {     0.06  ,   0.06  ,   0.06  };
  layer1Vars.rgbOffset =      new float[] {     0     ,   0     ,   0     };
  layer1Vars.baseColor =   new int[]   {    83     , 126     ,  77     };
  layer1Vars.omega =          .1;

  layer2Vars.rgbK =           new float[] {     0.02  ,   0.02  ,   0.02  };
  layer2Vars.rgbOffset =      new float[] {     0     ,   0     ,   0     };
  layer2Vars.baseColor =   new int[]   {   255     , 255     , 255     };
  layer2Vars.omega =          .1;

  layer3Vars.rgbK =           new float[] {     0.005 ,   0.005 ,   0.005 };
  layer3Vars.rgbOffset =      new float[] {     0     ,   0     ,   0     };
  layer3Vars.baseColor =   new int[]   {   255     , 255     , 255     };
  layer3Vars.omega =          .1;

  layer1 = createGraphics(width, height);
  layer2 = createGraphics(width, height);
  layer3 = createGraphics(width, height);

  physics = new VerletPhysics2D();

  Vec2D startingPoint;
  Vec2D sidePoint;
  Vec2D point2, point3, point4, point5;

  Vec2D startingPointLayer3;
  Vec2D sidePointLayer3;
  Vec2D point2Layer3, point3Layer3, point4Layer3, point5Layer3;

  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    startingPoint = randomPosition(new Rect(0, 0, width, height));
    sidePoint = randomPosition(new Rect(0, 0, randomInt(100, 400), 0));
    point2 = startingPoint.copy().add(sidePoint);
    point5 = startingPoint.copy().sub(sidePoint);

    beziers[i] = new Bezier5Path(
      new Vec2D[] {
        startingPoint,
        point2,
        randomPosition(new Rect(0, 0, width, height)),
        randomPosition(new Rect(0, 0, width, height)),
        point5,
        startingPoint
      },
      NUM_STEP_SEGMENTS
    );

    float[] anglesLayer1 = new float[NUM_STEP_SEGMENTS + 1];
    for (int stepN = 0; stepN < NUM_STEP_SEGMENTS + 1; stepN++) {
      anglesLayer1[stepN] = random(0, TWO_PI);
    }

    colorTrailsLayer1[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      anglesLayer1,
      2, 5,
      30, 50,
      4,
      1,
      .001
    );

    float[] anglesLayer2 = new float[NUM_STEP_SEGMENTS + 1];
    for (int stepN = 0; stepN < NUM_STEP_SEGMENTS + 1; stepN++) {
      if (stepN < NUM_STEP_SEGMENTS) {
        anglesLayer2[stepN] = beziers[i].path[stepN + 1].sub(beziers[i].path[stepN]).angleBetween(new Vec2D(0, 1), true);
      } else {
        anglesLayer2[stepN] = beziers[i].path[stepN].sub(beziers[i].path[stepN - 1]).angleBetween(new Vec2D(0, 1), true);
      }
    }
    colorTrailsLayer2[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      anglesLayer2,
      2, 5,
      100, 150,
      10,
      .1,
      .1
    );

    startingPointLayer3 = randomPosition(new Rect(0, 0, width, height));
    sidePointLayer3 = randomPosition(new Rect(0, 0, randomInt(100, 400), 0));
    point2Layer3 = startingPointLayer3.copy().add(sidePointLayer3);
    point5Layer3 = startingPointLayer3.copy().sub(sidePointLayer3);

    beziers[i] = new Bezier5Path(
      new Vec2D[] {
        startingPointLayer3,
        point2Layer3,
        randomPosition(new Rect(0, 0, width, height)),
        randomPosition(new Rect(0, 0, width, height)),
        point5Layer3,
        startingPointLayer3
      },
      NUM_STEP_SEGMENTS
    );

    float[] anglesLayer3 = new float[NUM_STEP_SEGMENTS + 1];
    for (int stepN = 0; stepN < NUM_STEP_SEGMENTS + 1; stepN++) {
      anglesLayer1[stepN] = random(0, TWO_PI);
    }
    colorTrailsLayer3[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      anglesLayer3,
      2, 5,
      200, 300,
      4,
      .1,
      .1
    );
  }

  int iterations = 1000;
  for (; iterations > 0; iterations--) {
    newStep();
  }
}

void draw() {
  background(220);
  image(layer3, 0, 0);
  image(layer2, 0, 0);
  image(layer1, 0, 0);
  if (video) {
    saveFrame("out/screen-####.tif");
    push();
    fill(255, 0, 0);
    noStroke();
    ellipse(30, height - 30, 10, 10);
    pop();
  }
  newStep();

  // noLoop();
}

void keyPressed() {
  int number = randomInt(0, 100);
  if (key == ' ') {
    saveFrame("out/screen-####.tif");
    // layer1.save("out/screen-####.png");
  }
  if (key == 'v') {
    video = !video;
    // layer1.save("out/screen-####.png");
  }
}

void newStep() {
  physics.update();
  layer1.beginDraw();
  float scale = 1;
  layer1.translate(width * (1 - scale) / 2, height * (1 - scale) / 2);
  layer1.scale(scale);
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrailsLayer1[i].finished()) {
      colorTrailsLayer1[i].backToOrigin();
      continue;
    }
    colorTrailsLayer1[i].update();
    colorTrailsLayer1[i].colorString.displayStraight(
      layer1,
      layer1Vars.rgbK,
      layer1Vars.baseColor,
      layer1Vars.rgbOffset,
      layer1Vars.omega + i
    );
    colorTrailsLayer1[i].colorString.displayOneInTwo(
      layer1,
      layer1Vars.rgbK,
      layer1Vars.baseColor,
      layer1Vars.rgbOffset,
      layer1Vars.omega + i
    );
  }
  layer1.endDraw();

  layer2.beginDraw();
  layer2.translate(width * (1 - scale) / 2, height * (1 - scale) / 2);
  layer2.scale(scale);
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrailsLayer2[i].finished()) {
      colorTrailsLayer2[i].backToOrigin();
      continue;
    }
    colorTrailsLayer2[i].update();
    colorTrailsLayer2[i].colorString.displayStraight(
      layer2,
      layer2Vars.rgbK,
      layer2Vars.baseColor,
      layer2Vars.rgbOffset,
      layer2Vars.omega
    );
    colorTrailsLayer2[i].colorString.displayOneInTwo(
      layer2,
      layer2Vars.rgbK,
      layer2Vars.baseColor,
      layer2Vars.rgbOffset,
      layer2Vars.omega
    );
  }
  layer2.endDraw();

  layer3.beginDraw();
  layer3.translate(width * (1 - scale) / 2, height * (1 - scale) / 2);
  layer3.scale(scale);
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrailsLayer3[i].finished()) {
      continue;
    }
    colorTrailsLayer3[i].update();
    colorTrailsLayer3[i].colorString.displayStraight(
      layer3,
      layer3Vars.rgbK,
      layer3Vars.baseColor,
      layer3Vars.rgbOffset,
      layer3Vars.omega
    );
    colorTrailsLayer3[i].colorString.displayOneInTwo(
      layer3,
      layer3Vars.rgbK,
      layer3Vars.baseColor,
      layer3Vars.rgbOffset,
      layer3Vars.omega
    );
  }
  layer3.endDraw();
}

// void mousePressed() {
//   int iterations = 1000;
//   for (; iterations > 0; iterations--) {
//     newStep();
//   }
//   loop();
// }
