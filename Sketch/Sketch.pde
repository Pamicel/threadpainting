import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;
import java.util.Iterator;

/* Utils */

int randomInt (int min, int max) {
  // Random int with evenly distributed probabilities
  return floor(random(min, max + 1));
}

int randomInt (int max) {
  return randomInt(0, max);
}

class LayerVariables {
  LayerVariables() {}
  public float[] rgbK;
  public int[] baseColor;
  public float[] rgbOffset;
  public float omega;
}

Vec2D randomPosition(Rect rectangle) {
  int xmin = (int)rectangle.x;
  int xmax = (int)(rectangle.x + rectangle.width);
  int ymin = (int)rectangle.y;
  int ymax = (int)(rectangle.y + rectangle.height);

  return new Vec2D(randomInt(xmin, xmax), randomInt(ymin, ymax));
}

/* */


/* Global variables */

VerletPhysics2D physics;

PGraphics layer1;

int realScale, realHeight, realWidth;

boolean video = false;

int SEED = 31;
int NUM_COLOR_TRAILS = 1;
int NUM_STEP_SEGMENTS = 50;
float CURVE_WIDTH_FACTOR = 5;
float MIN_SPEED_FACTOR = 10;
float MAX_SPEED_FACTOR = 20;
int MIN_RADIUS_FACTOR = 10;
int MAX_RADIUS_FACTOR = 500;
int N_LINKS = 4;
float MASS = 1;
float STRENGTH = .01;
int[] STARTING_POINT_COORD = new int[]{500, -300};
int[] SIDE_POINT_COORD = new int[]{1500, 300};

boolean SECONDARY_MONITOR = true;
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};
int[] DISPLAY_WIN_SIZE = new int[]{1000, 1000};


Bezier5Path[] beziers = new Bezier5Path[NUM_COLOR_TRAILS];

ToxiColorTrail[] colorTrailslayer1 = new ToxiColorTrail[NUM_COLOR_TRAILS];
LayerVariables layer1Vars = new LayerVariables();

/* */


void setup() {
  surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
  smooth();
  randomSeed(SEED);
  frameRate(60);


  realScale = 1;

  realWidth = width * realScale;
  realHeight = height * realScale;

  layer1Vars.rgbK = new float[] {
    realScale * 175,
    realScale * 175,
    realScale * 175
  };

  layer1Vars.rgbOffset = new float[] {
    5.5,
    5.5,
    5.5
  };
  layer1Vars.baseColor =      new int[]   {   255     , 255     , 255     };
  layer1Vars.omega = realScale * .1;

  layer1 = createGraphics(realWidth, realHeight);

  physics = new VerletPhysics2D();

  Vec2D startingPoint;
  Vec2D sidePoint;
  Vec2D point2, point3, point4, point5;

  int curveWidth = floor(CURVE_WIDTH_FACTOR * realWidth);

  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    startingPoint = new Vec2D(STARTING_POINT_COORD[0], STARTING_POINT_COORD[1]);
    sidePoint = new Vec2D(SIDE_POINT_COORD[0], SIDE_POINT_COORD[1]);
    point2 = startingPoint.copy().add(sidePoint);
    point5 = startingPoint.copy().sub(sidePoint);

    point3 = startingPoint.copy().add(0, curveWidth).add(new Vec2D(randomInt(curveWidth / 10, curveWidth), 0));
    point4 = startingPoint.copy().add(0, curveWidth).sub(new Vec2D(randomInt(curveWidth / 10, curveWidth), 0));

    float angle = random(0, TWO_PI);
    point2 = point2.rotate(angle);
    point5 = point5.rotate(angle);
    point3 = point3.rotate(angle);
    point4 = point4.rotate(angle);
    Vec2D translation = new Vec2D(randomInt(realWidth / 4, 3 * realWidth / 4), randomInt(realHeight / 4, 3 * realHeight / 4));
    startingPoint = startingPoint.add(translation);
    point2 = point2.add(translation);
    point5 = point5.add(translation);
    point3 = point3.add(translation);
    point4 = point4.add(translation);

    beziers[i] = new Bezier5Path(
      new Vec2D[] {
        startingPoint,
        point2,
        point3,
        point4,
        point5,
        startingPoint
      },
      NUM_STEP_SEGMENTS
    );

    float[] angleslayer1 = new float[NUM_STEP_SEGMENTS + 1];
    for (int stepN = 0; stepN < NUM_STEP_SEGMENTS + 1; stepN++) {
      if (stepN < NUM_STEP_SEGMENTS) {
        angleslayer1[stepN] = beziers[i].path[stepN + 1].sub(beziers[i].path[stepN]).angleBetween(new Vec2D(0, 1), true);
      } else {
        angleslayer1[stepN] = beziers[i].path[stepN].sub(beziers[i].path[stepN - 1]).angleBetween(new Vec2D(0, 1), true);
      }
    }
    colorTrailslayer1[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      angleslayer1,
      MIN_SPEED_FACTOR * realScale, MAX_SPEED_FACTOR * realScale,
      MIN_RADIUS_FACTOR * realScale, MAX_RADIUS_FACTOR * realScale,
      N_LINKS,
      MASS,
      STRENGTH
    );
  }

  // int iterations = 1000;
  // for (; iterations > 0; iterations--) {
  //   newStep();
  // }
}

void draw() {
  // int n = 3000;
  // while (n > 0) {
    background(233, 232, 228);
    image(layer1, 0, 0, width, height);
    // textSize(30);
    // fill(0);
    // int seconds = floor(millis() / 1000);
    // text(seconds + "s", 20, height - 120);
    // if (seconds > 0) {
    //   text(frameCount / seconds + "f/s", 20, height - 80);
    // } else {
    //   text("...f/s", 20, height - 80);
    // }
    // text(frameCount, 20, height - 40);
    // saveCurrentFrame();

    // if (video) {
    //   saveFrame("out/screen-####.tif");
    //   push();
    //   fill(255, 0, 0);
    //   noStroke();
    //   ellipse(30, height - 30, 10, 10);
    //   pop();
    // }

    newStep();
    // n--;
  // }

  // noLoop();
  // exit();
}

void saveCurrentFrame() {
  int date = (year() % 100) * 10000 + month() * 100 + day();
  int time = hour() * 10000 + minute() * 100 + second();
  saveFrame("out/seed-"+SEED+"_date-"+ date + "_time-"+ time + ".tif");
}

void saveLayer(PGraphics layer, String layerName) {
  int date = (year() % 100) * 10000 + month() * 100 + day();
  int time = hour() * 10000 + minute() * 100 + second();
  layer.save("out/layer-" + layerName + "_seed-"+SEED+"_date-"+ date + "_time-"+ time + ".tif");
}

void keyPressed() {
  int number = randomInt(0, 100);
  if (key == ' ') {
    saveCurrentFrame();
  }
  if (key == 'p') {
    saveCurrentFrame();
    saveLayer(layer1, "1");
  }
  if (key == 'v') {
    video = !video;
    // layer1.save("out/screen-####.png");
  }
}

void newStep() {
  physics.update();
  float scale = .2;

  layer1.beginDraw();
  layer1.translate(realWidth * (1 - scale) / 2, realHeight * (1 - scale) / 2);
  layer1.scale(scale);
  // int layer1Skipped = 0;
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrailslayer1[i].finished()) {
      // colorTrailslayer1[i].backToOrigin();
      // layer1Skipped++;
      continue;
      // stop();
      // return;
    }
    colorTrailslayer1[i].update();
    // colorTrailslayer1[i].colorString.displayStraight(
    //   layer1,
    //   layer1Vars.rgbK,
    //   layer1Vars.baseColor,
    //   layer1Vars.rgbOffset,
    //   layer1Vars.omega
    // );
    // colorTrailslayer1[i].colorString.displayOneInTwo(
    //   layer1,
    //   layer1Vars.rgbK,
    //   layer1Vars.baseColor,
    //   layer1Vars.rgbOffset,
    //   layer1Vars.omega
    // );
    // colorTrailslayer1[i].colorString.displayStraight(
    //   layer1,
    //   layer1Vars.rgbK,
    //   layer1Vars.baseColor,
    //   layer1Vars.rgbOffset,
    //   layer1Vars.omega
    // );
    colorTrailslayer1[i].colorString.displayOneInTwo(
      layer1,
      layer1Vars.rgbK,
      layer1Vars.baseColor,
      layer1Vars.rgbOffset,
      layer1Vars.omega
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
