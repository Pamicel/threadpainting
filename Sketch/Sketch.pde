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

int SEED = 1;
float LAYER_SCALE = .1;
int SCALE = 1;
float MIN_SPEED_FACTOR = 30;
float MAX_SPEED_FACTOR = 50;
int MIN_RADIUS_FACTOR = 10;
int MAX_RADIUS_FACTOR = 1000;
int N_LINKS = 10;
float MASS = 1;
float STRENGTH = .01;
int[] STARTING_POINT_COORD = new int[]{500, -300};
int[] SIDE_POINT_COORD = new int[]{1500, 300};

boolean SECONDARY_MONITOR = false;
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};

ToxiColorTrail colorTrail;
LayerVariables layer1Vars = new LayerVariables();

/* */

ArrayList<Vec2D> loadCurve() {
  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  JSONArray objectCurve = loadJSONArray("data/curve.json");
  for (int i = 0; i < objectCurve.size(); i++) {
    JSONObject point = objectCurve.getJSONObject(i);
    float x = point.getFloat("x") / LAYER_SCALE;
    float y = point.getFloat("y") / LAYER_SCALE;
    curve.add(new Vec2D(x, y));
  }
  return curve;
}

void init() {
  randomSeed(SEED);
  colorTrail = ToxiColorTrailFromCurve(
    physics,
    loadCurve(),
    MIN_SPEED_FACTOR * realScale, MAX_SPEED_FACTOR * realScale,
    MIN_RADIUS_FACTOR * realScale, MAX_RADIUS_FACTOR * realScale,
    N_LINKS,
    MASS,
    STRENGTH
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
  init();
}

void draw() {
  background(233, 232, 228);
  image(layer1, 0, 0, width, height);
  newStep();
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
  if (colorTrail.finished()) {
    return;
  }
  physics.update();
  layer1.beginDraw();
  layer1.scale(LAYER_SCALE);
  colorTrail.update();
  colorTrail.colorString.displayOneInTwo(
    layer1,
    layer1Vars.rgbK,
    layer1Vars.baseColor,
    layer1Vars.rgbOffset,
    layer1Vars.omega
  );
  layer1.endDraw();
}