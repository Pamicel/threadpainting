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
PGraphics layer2;
PGraphics layer3;

int realScale, realHeight, realWidth;

boolean video = false;

int SEED = 6;
int NUM_COLOR_TRAILS = 10;
int NUM_STEP_SEGMENTS = 30;
float CURVE_WIDTH_FACTOR = 1;
Bezier5Path[] beziers = new Bezier5Path[NUM_COLOR_TRAILS];

ToxiColorTrail[] colorTrailsLayer1 = new ToxiColorTrail[NUM_COLOR_TRAILS];
ToxiColorTrail[] colorTrailsLayer2 = new ToxiColorTrail[NUM_COLOR_TRAILS];
ToxiColorTrail[] colorTrailsLayer3 = new ToxiColorTrail[NUM_COLOR_TRAILS];

LayerVariables layer1Vars = new LayerVariables();
LayerVariables layer2Vars = new LayerVariables();
LayerVariables layer3Vars = new LayerVariables();

/* */


void setup() {
  size(1000, 1000);
  smooth();
  randomSeed(SEED);

  realScale = 1;

  realWidth = width * realScale;
  realHeight = height * realScale;

  layer1Vars.rgbK = new float[] {
    realScale * 80,
    realScale * 80,
    realScale * 80
  };

  layer1Vars.rgbOffset =      new float[] {
    2.8,
    2.8,
    2.8
  };
  layer1Vars.baseColor = new int[] { 232, 232, 228 };
  layer1Vars.omega = realScale * .5;

  layer2Vars.rgbK = new float[] {
    realScale * 175,
    realScale * 175,
    realScale * 175
  };

  layer2Vars.rgbOffset = new float[] {
    5.5,
    5.5,
    5.5
  };
  layer2Vars.baseColor =      new int[]   {   255     , 255     , 255     };
  layer2Vars.omega = realScale * .1;

  layer3Vars.rgbK = new float[] {
    realScale * 0,
    realScale * 50,
    realScale * 50
  };

  layer3Vars.rgbOffset =      new float[] {     0.1   ,  -3.2   ,   1.5   };
  layer3Vars.baseColor =      new int[]   {   255     , 255     , 255     };
  layer3Vars.omega = realScale * .1;

  layer1 = createGraphics(realWidth, realHeight);
  layer2 = createGraphics(realWidth, realHeight);
  layer3 = createGraphics(realWidth, realHeight);

  physics = new VerletPhysics2D();

  Vec2D startingPoint;
  Vec2D sidePoint;
  Vec2D point2, point3, point4, point5;

  Vec2D startingPointLayer3;
  Vec2D sidePointLayer3;
  Vec2D point2Layer3, point3Layer3, point4Layer3, point5Layer3;

  int curveWidth = floor(CURVE_WIDTH_FACTOR * realWidth);

  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    startingPoint = new Vec2D(0, 0);
    sidePoint = new Vec2D(randomInt(curveWidth / 10, curveWidth / 2), 0);
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

    float[] anglesLayer1 = new float[NUM_STEP_SEGMENTS + 1];
    for (int stepN = 0; stepN < NUM_STEP_SEGMENTS + 1; stepN++) {
      anglesLayer1[stepN] = PI;
    }

    colorTrailsLayer1[i] = ToxiColorTrailFromBezier(
      physics,
      beziers[i],
      anglesLayer1,
      2 * realScale, 2 * realScale,
      10 * realScale, 50 * realScale,
      10,
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
      2 * realScale, 5 * realScale,
      200 * realScale, 300 * realScale,
      30,
      1,
      .1
    );

    startingPointLayer3 = randomPosition(new Rect(0, 0, realWidth, realHeight));
    sidePointLayer3 = randomPosition(new Rect(0, 0, randomInt(100, 400), 0));
    point2Layer3 = startingPointLayer3.copy().add(sidePointLayer3);
    point5Layer3 = startingPointLayer3.copy().sub(sidePointLayer3);

    int STEPS_LAYER_3 = 4;
    float[] anglesLayer3 = new float[STEPS_LAYER_3 + 1];
    for (int stepN = 0; stepN < STEPS_LAYER_3 + 1; stepN++) {
      anglesLayer1[stepN] = PI;
    }
    int paddingX = 300;
    int paddingY = 200;
    colorTrailsLayer3[i] = randomToxiColorTrail(
      physics,
      new Rect(paddingX, paddingY, realWidth - (2 * paddingX), realHeight - 2 * paddingY),
      anglesLayer3,
      2, 2,
      80 * realScale, 120 * realScale,
      10,
      1,
      .001
    );
  }

  // int iterations = 1000;
  // for (; iterations > 0; iterations--) {
  //   newStep();
  // }
}

void draw() {
  background(233, 232, 228);

  // image(layer3, 0, 0);
  image(layer2, 0, 0, width, height);
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
    saveLayer(layer2, "2");
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
  layer1.translate(realWidth * (1 - scale) / 2, realHeight * (1 - scale) / 2);
  layer1.scale(scale);
  // int layer1Skipped = 0;
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrailsLayer1[i].finished()) {
      colorTrailsLayer1[i].backToOrigin();
      // layer1Skipped++;
      continue;
    }
    colorTrailsLayer1[i].update();
    // colorTrailsLayer1[i].colorString.displayStraight(
    //   layer1,
    //   layer1Vars.rgbK,
    //   layer1Vars.baseColor,
    //   layer1Vars.rgbOffset,
    //   layer1Vars.omega
    // );
    colorTrailsLayer1[i].colorString.displayOneInTwo(
      layer1,
      layer1Vars.rgbK,
      layer1Vars.baseColor,
      layer1Vars.rgbOffset,
      layer1Vars.omega
    );
  }
  layer1.endDraw();

  layer2.beginDraw();
  layer2.translate(realWidth * (1 - scale) / 2, realHeight * (1 - scale) / 2);
  layer2.scale(scale);
  // int layer2Skipped = 0;
  for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
    if (colorTrailsLayer2[i].finished()) {
      // colorTrailsLayer2[i].backToOrigin();
      // layer2Skipped++;
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

  // if (layer1Skipped == NUM_COLOR_TRAILS && layer2Skipped == NUM_COLOR_TRAILS) {

  // }

  // layer3.beginDraw();
  // for(int i = 0; i < NUM_COLOR_TRAILS; i++) {
  //   if (colorTrailsLayer3[i].finished()) {
  //     continue;
  //   }
  //   colorTrailsLayer3[i].update();
  //   colorTrailsLayer3[i].colorString.displayStraight(
  //     layer3,
  //     layer3Vars.rgbK,
  //     layer3Vars.baseColor,
  //     layer3Vars.rgbOffset,
  //     layer3Vars.omega + i
  //   );
  //   colorTrailsLayer3[i].colorString.displayOneInTwo(
  //     layer3,
  //     layer3Vars.rgbK,
  //     layer3Vars.baseColor,
  //     layer3Vars.rgbOffset,
  //     layer3Vars.omega + i
  //   );
  // }
  // layer3.endDraw();
}

// void mousePressed() {
//   int iterations = 1000;
//   for (; iterations > 0; iterations--) {
//     newStep();
//   }
//   loop();
// }
