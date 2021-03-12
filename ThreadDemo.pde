import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

PGraphics layer1;

int SEED = 1;
int NUM_COLOR_TRAILS = 1;
int NUM_STEPS = 50;
Vec2D[] pointsAlongBezier = new Vec2D[NUM_STEPS + 1];

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

class BezierDegree5 {
  Vec2D[] points;

  BezierDegree5(Vec2D[] points) {
    if (points.length != 6) {
      throw new Error("Bezier of degree 5 requires 6 points");
    }
    this.points = points;
  }

  Vec2D getPosition (float t) {
    if (t <= 0) {
      return this.points[0];
    } if (t >= 1) {
      return this.points[5];
    }

    float factor0 = pow((1 - t), 5);
    float factor1 = 5 * t * pow((1 - t), 4);
    float factor2 = 10 * pow(t, 2) * pow((1 - t), 3);
    float factor3 = 10 * pow(t, 3) * pow((1 - t), 2);
    float factor4 = 5 * pow(t, 4) * (1 - t);
    float factor5 = pow(t, 5);

    float x =
      factor0 * this.points[0].x
      + factor1 * this.points[1].x
      + factor2 * this.points[2].x
      + factor3 * this.points[3].x
      + factor4 * this.points[4].x
      + factor5 * this.points[5].x;

    float y =
      factor0 * this.points[0].y
      + factor1 * this.points[1].y
      + factor2 * this.points[2].y
      + factor3 * this.points[3].y
      + factor4 * this.points[4].y
      + factor5 * this.points[5].y;

    return new Vec2D(x, y);
  }
}

ToxiColorTrail ToxiColorTrailFromBezier(
  VerletPhysics2D physics,
  BezierDegree5 bezier,
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

    pointsAlongBezier[i] = bezier.getPosition((float)i / numSteps);

    targets[i] = new ColorTrailTarget(
      pointsAlongBezier[i],
      floor(random(minRadius, maxRadius)),
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

  layer1 = createGraphics(width, height);

  physics = new VerletPhysics2D();

  Vec2D startingPoint = new Vec2D(width / 4, height / 4);
  Vec2D sidePoint = new Vec2D(random(0, 100), random(0, 100));
  Vec2D point2 = startingPoint.copy().add(sidePoint);
  Vec2D point4 = startingPoint.copy().sub(sidePoint);

  BezierDegree5 bezier = new BezierDegree5(
    new Vec2D[] {
      startingPoint,
      point2,
      new Vec2D(random(width, width * 2), random(0, height)),
      new Vec2D(random(0, width), random(height, height * 2)),
      point4,
      startingPoint
    }
  );

  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    colorTrailsLayer1[i] = ToxiColorTrailFromBezier(
      physics,
      bezier,
      50,
      2, 2,
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
  push();
  stroke(255);
  noFill();
  for (int i = 0; i < NUM_STEPS; i++) {
    point(pointsAlongBezier[i].x, pointsAlongBezier[i].y);
  }
  pop();
  // noLoop();
  newStep();
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
