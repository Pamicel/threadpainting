import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

PGraphics layer1;

int randomInt (int min, int max) {
  // Random int with evenly distributed probabilities
  return floor(random(min, max + 1));
}

int randomInt (int max) {
  return randomInt(0, max);
}

int SEED = 10;
int NUM_COLOR_TRAILS = 20;
int NUM_STEPS = 50;
Bezier5Path[] beziers = new Bezier5Path[NUM_COLOR_TRAILS];

ToxiColorTrail[] colorTrailsLayer1 = new ToxiColorTrail[NUM_COLOR_TRAILS];

class LayerVariables {
  LayerVariables() {}
  public float[] rgbK;
  public float[] rgbIntensity;
  public float[] rgbOffset;
  public float omega;
}

LayerVariables layer1Vars = new LayerVariables();

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
      bezier.path[i],
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

  layer1Vars.rgbK = new float[] { 0.05, 0.1, 0.1 };
  layer1Vars.rgbOffset = new float[]{ 0.2, 0.1, 5.6 };
  layer1Vars.rgbIntensity = new float[] { 1, 0.4, 1 };
  layer1Vars.omega = .1;

  layer1 = createGraphics(width, height);

  physics = new VerletPhysics2D();

  Vec2D startingPoint;
  Vec2D sidePoint;
  Vec2D point2, point3, point4, point5;

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
      NUM_STEPS
    );
    colorTrailsLayer1[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      50,
      2, 5,
      30, 50,
      4,
      1,
      .001
    );
  }
}

void draw() {
  background(255);
  image(layer1, 0, 0);
  newStep();
  // noLoop();
}

void keyPressed() {
  int number = randomInt(0, 100);
  if (key == ' ') {
    saveFrame("out/screen-####.tif");
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
      continue;
    }
    colorTrailsLayer1[i].update();
    colorTrailsLayer1[i].colorString.displayStraight(
      layer1,
      layer1Vars.rgbK,
      layer1Vars.rgbIntensity,
      layer1Vars.rgbOffset,
      layer1Vars.omega + i
    );
    colorTrailsLayer1[i].colorString.displayOneInTwo(
      layer1,
      layer1Vars.rgbK,
      layer1Vars.rgbIntensity,
      layer1Vars.rgbOffset,
      layer1Vars.omega + i
    );
  }
  layer1.endDraw();
}

// void mousePressed() {
//   int iterations = 1000;
//   for (; iterations > 0; iterations--) {
//     newStep();
//   }
//   loop();
// }
