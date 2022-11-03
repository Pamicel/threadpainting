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

PGraphics layer1, printLayer;

int realScale, realHeight, realWidth;

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
int[] TRAIL_COLOR = new int[] { 0, 0, 0 };
int[] BASE_COLOR = new int[] { 0, 0, 0 };
float[] RGB_K = new float[] { 1, 1, 1 };
float COLOR_OMEGA_TWO_PI = -1;
float ANGLE_VARIABILITY = 0;
boolean RESAMPLE = false;
boolean RESAMPLE_REGULAR = false;
int RESAMPLE_LEN = 12;
int CYCLE_LEN = 8500;
int stepCount = 0;
enum Output { VIDEO, DRAW };
Output OUTPUT = Output.VIDEO;
int VIDEO_NUM_FRAMES = 10;
float PARTICLE_DIAMETER_FACTOR = 1.0;
int videoFrameCount = 0;

float MASS = 1;
boolean SECONDARY_MONITOR = false;
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};

TrailRenderer[] TRAIL_RENDERERS;
LayerVariables layer1Vars = new LayerVariables();

enum OverallShape {BIG_TO_SMALL, SMALL_TO_BIG, CONSTANT};
OverallShape TYPE_OF_OVERALL_SHAPE = OverallShape.CONSTANT;

Vec2D[] SIMPLE_CURVE;
Vec2D[] STROK_HEAD_CURVE;
Vec2D[] STROK_TAIL_CURVE;
String CURVE_TYPE = "SIMPLE_CURVE"; // Or STROK_CURVE
String CURVE_PATH = "config/curve.json";

interface RenderingStep {
  void render();
};
RenderingStep[] renderingPipeline;
String[] renderingStepNames;

/* */

Vec2D[] curveFromJSONArray(JSONArray rawCurve) {
  Vec2D[] curve = new Vec2D[rawCurve.size()];
  for (int i = 0; i < rawCurve.size(); i++) {
    JSONObject point = rawCurve.getJSONObject(i);
    float x = point.getFloat("x") / LAYER_SCALE;
    float y = point.getFloat("y") / LAYER_SCALE;
    curve[i] = new Vec2D(x, y);
  }
  return curve;
}

Vec2D[] applyResampleToCurve(Vec2D[] curve) {
  if (RESAMPLE && RESAMPLE_LEN != 0) {
    if (RESAMPLE_REGULAR) {
      return regularResample(curve, RESAMPLE_LEN);
    }
    return resample(curve, RESAMPLE_LEN);
  }
  return curve;
}

void loadCurve() {
  if (CURVE_TYPE.equals("STROK_CURVE")) {
    JSONObject namedCurves = loadJSONObject(CURVE_PATH);
    JSONObject curveDescriptions = namedCurves.getJSONObject("curves");
    JSONArray rawHeadCurve = curveDescriptions.getJSONArray("headCurve");
    JSONArray rawTailCurve = curveDescriptions.getJSONArray("tailCurve");
    Vec2D[] headCurve = curveFromJSONArray(rawHeadCurve);
    Vec2D[] tailCurve = curveFromJSONArray(rawTailCurve);
    STROK_HEAD_CURVE = applyResampleToCurve(headCurve);
    STROK_TAIL_CURVE = applyResampleToCurve(tailCurve);
  } else {
    JSONArray rawCurve = loadJSONArray(CURVE_PATH);
    Vec2D[] curve = curveFromJSONArray(rawCurve);
    SIMPLE_CURVE = applyResampleToCurve(curve);
  }
}

void loadVariables() {
  JSONObject variables = loadJSONObject("config/variables.json");
  SEED = variables.getInt("seed");
  // Rendering
  STEPS_PER_DRAW = variables.getInt("stepsPerDraw");
  String outputType = variables.getString("output");
  if (outputType.equals("VIDEO")) {
    OUTPUT = Output.VIDEO;
  } else {
    OUTPUT = Output.DRAW;
  }
  VIDEO_NUM_FRAMES = variables.getInt("videoNumFrames");

  // Curve
  RESAMPLE = variables.getBoolean("resample");
  RESAMPLE_REGULAR = variables.getBoolean("resampleRegular");
  RESAMPLE_LEN = variables.getInt("resampleLen");
  JSONObject curve = variables.getJSONObject("curve");
  if (curve != null) {
    CURVE_TYPE = curve.getString("type");
    String pathName = curve.getString("pathName");
    String curvePathsFile = "config/paths/simpleCurvePaths.json";
    if (CURVE_TYPE.equals("STROK_CURVE")) {
      curvePathsFile = "config/paths/strokCurvePaths.json";
    }
    JSONObject curvePaths = loadJSONObject(curvePathsFile);
    CURVE_PATH = curvePaths.getString(pathName);
    println(CURVE_PATH);
    if (CURVE_PATH == null) {
      throw new Error("Path name " + pathName + " is not defined in " + curvePathsFile);
    }
  }

  // Trails
  JSONArray trails = variables.getJSONArray("trails");
  TRAIL_RENDERERS = new TrailRenderer[trails.size()];
  for (int i = 0; i < trails.size(); i++) {
    TRAIL_RENDERERS[i] = new TrailRenderer();
    TrailRenderer renderer = TRAIL_RENDERERS[i];
    JSONObject trailVariables = trails.getJSONObject(i);
    renderer.minSpeedFactor = trailVariables.getFloat("minSpeedFactor");
    renderer.maxSpeedFactor = trailVariables.getFloat("maxSpeedFactor");
    renderer.nLinks = trailVariables.getInt("nLinks");
    renderer.strength = trailVariables.getFloat("strength");
    renderer.mass = MASS;
    renderer.angleVariability = trailVariables.getFloat("angleVariability");
    renderer.minRadiusFactor = trailVariables.getFloat("minRadiusFactor");
    renderer.maxRadiusFactor = trailVariables.getFloat("maxRadiusFactor");

    String typeOfOverallShape = trailVariables.getString("typeOfOverallShape");
    if (typeOfOverallShape.equals("SMALL_TO_BIG")) {
      renderer.typeOfOverallShape = OverallShape.SMALL_TO_BIG;
    } else if (typeOfOverallShape.equals("BIG_TO_SMALL")) {
      renderer.typeOfOverallShape = OverallShape.BIG_TO_SMALL;
    } else {
      renderer.typeOfOverallShape = OverallShape.CONSTANT;
    }

    JSONArray trailColor = trailVariables.getJSONArray("trailColor");
    for (int colorIndex = 0; colorIndex < trailColor.size(); colorIndex++) {
      renderer.trailColor[colorIndex] = trailColor.getInt(colorIndex);
    }

    renderer.particleDiameterFactor = trailVariables.getFloat("particleDiamFactor");

    JSONArray renderingPipelineArray = trailVariables.getJSONArray("renderingPipeline");
    renderer.renderingStepNames = new String[renderingPipelineArray.size()];
    for (int stepIndex = 0; stepIndex < renderingPipelineArray.size(); stepIndex++) {
      renderer.renderingStepNames[stepIndex] = renderingPipelineArray.getString(stepIndex);
    }
  }

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

void loadConfig() {
  clear();
  loadVariables();
  loadCurve();
}

void clear() {
  // Remove the color springs from the simulation
  if (TRAIL_RENDERERS != null) {
    for (TrailRenderer renderer: TRAIL_RENDERERS) {
      renderer.clear();
    }
  }
}

boolean allTrailRenderersFinished() {
  boolean allFinished = true;
  for (TrailRenderer renderer: TRAIL_RENDERERS) {
    allFinished = allFinished && renderer.finished();
  }
  return allFinished;
}

void init() {
  realScale = SCALE;

  realWidth = width * realScale;
  realHeight = height * realScale;

  layer1 = createGraphics(realWidth, realHeight);
  printLayer = createGraphics(realWidth, realHeight);

  stepCount = 0;

  layer1Vars.rgbK = RGB_K;
  layer1Vars.rgbOffset = new float[] { 0, 0, 0 };
  layer1Vars.baseColor = BASE_COLOR;
  layer1Vars.omega = COLOR_OMEGA_TWO_PI * TWO_PI;

  for (TrailRenderer renderer: TRAIL_RENDERERS) {
    randomSeed(SEED);
    if (CURVE_TYPE.equals("SIMPLE_CURVE")) {
      renderer.initFromCurve(
        physics,
        SIMPLE_CURVE,
        realScale,
        layer1,
        layer1Vars
      );
    } else if (CURVE_TYPE.equals("STROK_CURVE")) {
      renderer.initFromStrok(
        physics,
        STROK_HEAD_CURVE,
        STROK_TAIL_CURVE,
        realScale,
        layer1,
        layer1Vars
      );
    }
  }

  layer1.beginDraw();
  layer1.clear();
  // layer1.blendMode(BLEND);
  layer1.endDraw();
}

void setup() {
  surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  size(1000, 1000);
  smooth();
  physics = new VerletPhysics2D();
  loadConfig();
  init();

  if (OUTPUT == Output.VIDEO) {
    noLoop();
    while (videoFrameCount < VIDEO_NUM_FRAMES) {
      float startTime = millis();
      println("VIDEO: rendering frame " + videoFrameCount);
      init();
      while (!allTrailRenderersFinished()) {
        newStep();
      }
      saveLayerAsVideoFrame(layer1);
      float time = millis() - startTime;
      println("VIDEO: frame " + videoFrameCount + " saved, time " + (time / 1000) + " sec");
      println("VIDEO: est. time remaining " + ((time * (VIDEO_NUM_FRAMES - videoFrameCount)) / 1000 / 60) + " min");
      videoFrameCount++;
    }
  }
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

void printComposition() {
  String date = "" + year() + String.format("%02d", month()) + String.format("%02d", day());
  String time = String.format("%02d", hour()) + ":" + String.format("%02d", minute()) + ":" + String.format("%02d", second());
  String fileName = date + "T" + time + "-composition.tif";
  printLayer.beginDraw();
  printLayer.clear();
  printLayer.background(BACKGROUND_COLOR[0], BACKGROUND_COLOR[1], BACKGROUND_COLOR[2]);
  printLayer.image(layer1, 0, 0, printLayer.width, printLayer.height);
  printLayer.endDraw();
  printLayer.save("out/" + fileName);
}

void saveLayerAsVideoFrame(PGraphics layer) {
  layer.save("video/frame" + String.format("%04d", videoFrameCount) + ".tif");
}

void keyPressed() {
  int number = randomInt(0, 100);
  if (key == ' ') {
    saveCurrentFrame();
  }
  if (key == 'p') {
    printComposition();
  }
  if (key == 's') {
    saveLayer(layer1, "1");
  }
  if (key == 'l') {
    loadConfig();
    init();
  }
}

void newStep() {
  physics.update();
  layer1.beginDraw();
  layer1.scale(LAYER_SCALE);
  // rendering steps
  for (TrailRenderer renderer: TRAIL_RENDERERS) {
    renderer.render();
  }
  layer1.endDraw();
}