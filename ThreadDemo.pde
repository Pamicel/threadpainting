import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

PGraphics layer1;

int SEED = 1;
int NUM_COLOR_TRAILS = 5;
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
    push();
    fill(255);
    noStroke();
    for (int i = 0; i < this.numSteps + 1; i++) {
      push();
      translate(this.path[i].x, this.path[i].y);
      ellipse(0, 0, 8, 8);
      pop();
    }
    pop();
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
      floor(random(minRadius, maxRadius)),
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
  layer1Vars.rgbIntensity = new float[] { 1, 0.2, 1 };
  layer1Vars.rgbOffset = new float[]{ 0, 0, 8.5 };
  layer1Vars.omega = .1;

  layer1 = createGraphics(width, height);

  physics = new VerletPhysics2D();

  Vec2D startingPoint = new Vec2D(width / 5, height / 5);
  Vec2D sidePoint = new Vec2D(random(0, 400), random(0, 400));
  Vec2D point2 = startingPoint.copy().add(sidePoint);
  Vec2D point4 = startingPoint.copy().sub(sidePoint);

  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    beziers[i] = new Bezier5Path(
      new Vec2D[] {
        startingPoint,
        point2,
        new Vec2D(random(width, width * 1.5), random(0, height)),
        new Vec2D(random(0, width), random(height, height * 1.5)),
        point4,
        startingPoint
      },
      NUM_STEPS
    );
    colorTrailsLayer1[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      50,
      2, 5,
      100, 150,
      4,
      1,
      .001
    );
  }
}

void draw() {
  background(255);
  image(layer1, 0, 0);
  // noLoop();
  newStep();
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    beziers[i].display();
  }
}

void keyPressed() {
  if (key == ' ') {
    saveFrame("out/screen-####.tif");
  }
}

void newStep() {
  physics.update();
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

void mousePressed() {
  int iterations = 1000;
  for (; iterations > 0; iterations--) {
    newStep();
  }
  loop();
}
