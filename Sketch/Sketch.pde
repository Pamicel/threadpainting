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

// Default variables
int SEED = 5;
float LAYER_SCALE = .1;
int SCALE = 1;
float MIN_SPEED_FACTOR = 5;
float MAX_SPEED_FACTOR = 10;
int MIN_RADIUS_FACTOR = 100;
int MAX_RADIUS_FACTOR = 2000;
int N_LINKS = 100;
float STRENGTH = .01;
int STEPS_PER_DRAW = 20;
int[] BACKGROUND_COLOR = new int[] { 0, 0, 0 };
int[] BASE_COLOR = new int[] { 0, 0, 0 };
float[] RGB_K = new float[] { 1, 1, 1 };
float COLOR_OMEGA_TWO_PI = -1;
float ANGLE_VARIABILITY = 1.0;
boolean RESAMPLE = false;
boolean RESAMPLE_REGULAR = false;
int RESAMPLE_LEN = 12;
int CYCLE_LEN = 8500;
int stepCount = 0;

float MASS = 1;
boolean SECONDARY_MONITOR = false;
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};

ToxiColorTrail colorTrail;
LayerVariables layer1Vars = new LayerVariables();

/* */

Vec2D[] loadCurve() {
  JSONArray objectCurve = loadJSONArray("data/curve.json");
  Vec2D[] curve = new Vec2D[objectCurve.size()];
  for (int i = 0; i < objectCurve.size(); i++) {
    JSONObject point = objectCurve.getJSONObject(i);
    float x = point.getFloat("x") / LAYER_SCALE;
    float y = point.getFloat("y") / LAYER_SCALE;
    curve[i] = new Vec2D(x, y);
  }
  if (RESAMPLE && RESAMPLE_LEN != 0) {
    if (RESAMPLE_REGULAR) {
      return regularResample(curve, RESAMPLE_LEN);
    }
    return resample(curve, RESAMPLE_LEN);
  }
  return curve;
}

void loadVariables() {
  JSONObject variables = loadJSONObject("data/variables.json");
  SEED = variables.getInt("seed");
  MIN_SPEED_FACTOR = variables.getFloat("minSpeedFactor");
  MAX_SPEED_FACTOR = variables.getFloat("maxSpeedFactor");
  MIN_RADIUS_FACTOR = variables.getInt("minRadiusFactor");
  MAX_RADIUS_FACTOR = variables.getInt("maxRadiusFactor");
  N_LINKS = variables.getInt("nLinks");
  STRENGTH = variables.getFloat("strength");
  ANGLE_VARIABILITY = variables.getFloat("angleVariability");

  RESAMPLE = variables.getBoolean("resample");
  RESAMPLE_REGULAR = variables.getBoolean("resampleRegular");
  RESAMPLE_LEN = variables.getInt("resampleLen");

  // Rendering
  STEPS_PER_DRAW = variables.getInt("stepsPerDraw");

  // Colors
  COLOR_OMEGA_TWO_PI = variables.getFloat("colorOmegaTwoPi");
  JSONArray backgroundColor = variables.getJSONArray("backgroundColor");
  for (int i = 0; i < BACKGROUND_COLOR.length; i++) {
    BACKGROUND_COLOR[i] = backgroundColor.getInt(i);
  }
  JSONArray baseColor = variables.getJSONArray("baseColor");
  for (int i = 0; i < BASE_COLOR.length; i++) {
    BASE_COLOR[i] = baseColor.getInt(i);
  }
  JSONArray rgbK = variables.getJSONArray("rgbK");
  for (int i = 0; i < BASE_COLOR.length; i++) {
    RGB_K[i] = rgbK.getFloat(i);
  }
}

void init() {
  stepCount = 0;
  loadVariables();

  layer1Vars.rgbK = RGB_K;
  layer1Vars.rgbOffset = new float[] { 0, 0, 0 };
  layer1Vars.baseColor = BASE_COLOR;
  layer1Vars.omega = COLOR_OMEGA_TWO_PI * TWO_PI;

  randomSeed(SEED);

  colorTrail = ToxiColorTrailFromCurve(
    physics,
    loadCurve(),
    MIN_SPEED_FACTOR * realScale, MAX_SPEED_FACTOR * realScale,
    MIN_RADIUS_FACTOR * realScale, MAX_RADIUS_FACTOR * realScale,
    N_LINKS,
    MASS,
    STRENGTH,
    ANGLE_VARIABILITY
  );

  layer1.beginDraw();
  layer1.clear();
  layer1.endDraw();
}

void setup() {
  surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  size(1000, 1000);
  smooth();
  randomSeed(SEED);
  frameRate(60);

  realScale = SCALE;

  realWidth = width * realScale;
  realHeight = height * realScale;


  layer1 = createGraphics(realWidth, realHeight);

  physics = new VerletPhysics2D();
  init();
}

void draw() {
  background(BACKGROUND_COLOR[0], BACKGROUND_COLOR[1], BACKGROUND_COLOR[2]);
  image(layer1, 0, 0, width, height);
  for(int i = 0; i < STEPS_PER_DRAW; i++) {
    newStep();
  }
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
  if (key == 'l') {
    init();
  }
}

void newStep() {
  stepCount++;
  float cycleProgress = (float(stepCount) / float(CYCLE_LEN)) % 1.0;
  if (colorTrail.finished()) {
    return;
  }
  physics.update();
  layer1.beginDraw();
  layer1.scale(LAYER_SCALE);
  colorTrail.update();
  colorTrail.colorString.display(
    layer1,
    layer1Vars.rgbK,
    layer1Vars.baseColor,
    layer1Vars.rgbOffset,
    layer1Vars.omega,
    cycleProgress
  );
  // colorTrail.colorString.displayOneInTwo(
  //   layer1,
  //   layer1Vars.rgbK,
  //   layer1Vars.baseColor,
  //   layer1Vars.rgbOffset,
  //   layer1Vars.omega
  // );
  // colorTrail.colorString.displaySkeleton(
  //   layer1,
  //   cycleProgress
  // );
  // colorTrail.colorString.displayPoints(
  //   layer1
  // );
  // colorTrail.colorString.displayStraight(
  //   layer1,
  //   layer1Vars.rgbK,
  //   layer1Vars.baseColor,
  //   layer1Vars.rgbOffset,
  //   layer1Vars.omega
  // );
  layer1.endDraw();
}