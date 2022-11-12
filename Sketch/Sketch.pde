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
String IMAGE_OUTPUT_FOLDER = "out/";
float VIDEO_ANGLE_INCREMENT = -0.01;
float VIDEO_RADIUS_INCREMENT = 0;
PImage BACKGROUND_IMAGE;

float MASS = 1;
boolean SECONDARY_MONITOR = false;
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{0, 0};

TrailRenderer[] TRAIL_RENDERERS;

enum OverallShape {BIG_TO_SMALL, SMALL_TO_BIG, CONSTANT};
OverallShape TYPE_OF_OVERALL_SHAPE = OverallShape.CONSTANT;

Vec2D[] SINGLE_CURVE;
Vec2D[] STROK_HEAD_CURVE;
Vec2D[] STROK_TAIL_CURVE;
String CURVE_TYPE = "SINGLE_CURVE"; // Or STROK_CURVE
String CURVE_PATH = "config/defaults/singleCurve.json";
String VARIABLES_PATH;

Sequence SEQUENCE;

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

class ResampleConfig {
  ResampleConfig() {}
  boolean resample;
  boolean resampleRegular;
  int resampleLen;
}

class Sequence {
  int repeat;
  int repeatCounter = 0;
  JSONArray steps;
  int stepCounter = 0;

  Sequence(
    JSONArray steps,
    int repeat
  ) {
    this.steps = steps;
    this.repeat = repeat;
    this.repeatCounter = 0;
    this.stepCounter = 0;
  }

  int len() {
    return this.steps.size();
  }

  void next() {
    this.stepCounter++;
    if (this.stepCounter == this.len()) {
      this.stepCounter = 0;
      this.repeatCounter++;
    }
  }

  boolean finished() {
    return this.repeatCounter == this.repeat;
  }

  boolean isAtFirstStep() {
    return this.stepCounter == 0;
  }

  boolean isAtFirstRepeat() {
    return this.repeatCounter == 0;
  }

  String currentStep() {
    return this.steps.getString(this.stepCounter);
  }
}

Vec2D[] applyResampleToCurve(Vec2D[] curve, ResampleConfig resampleConfig) {
  int resampleLen = resampleConfig.resampleLen;
  boolean resample = resampleConfig.resample;
  boolean resampleRegular = resampleConfig.resampleRegular;

  if (resample && resampleLen != 0) {
    if (resampleRegular) {
      return regularResample(curve, resampleLen);
    }
    return resample(curve, resampleLen);
  }
  return curve;
}

HashMap<String, Vec2D[]> loadStrokCurves(
  String curvePath,
  ResampleConfig resampleConfig
) {
  JSONObject namedCurves = loadJSONObject(curvePath);
  JSONObject curveDescriptions = namedCurves.getJSONObject("curves");
  JSONArray rawHeadCurve = curveDescriptions.getJSONArray("headCurve");
  JSONArray rawTailCurve = curveDescriptions.getJSONArray("tailCurve");
  Vec2D[] headCurve = curveFromJSONArray(rawHeadCurve);
  Vec2D[] tailCurve = curveFromJSONArray(rawTailCurve);
  HashMap<String, Vec2D[]> curves = new HashMap<String, Vec2D[]>();
  curves.put("headCurve", applyResampleToCurve(headCurve, resampleConfig));
  curves.put("tailCurve", applyResampleToCurve(tailCurve, resampleConfig));
  return curves;
}

Vec2D[] loadSingleCurve(
  String curvePath,
  ResampleConfig resampleConfig
) {
  JSONArray rawCurve = loadJSONArray(curvePath);
  Vec2D[] curve = curveFromJSONArray(rawCurve);
  return applyResampleToCurve(curve, resampleConfig);
}

class CurveInfos {
  String path;
  String type;
  CurveInfos() {};
}

CurveInfos loadCurveInfos(String pathName) {
  CurveInfos curveInfos = new CurveInfos();
  String curvePathsFile = "config/paths/curvePaths.json";
  JSONObject allCurvePaths = loadJSONObject(curvePathsFile);
  JSONObject rawCurveInfo = allCurvePaths.getJSONObject(pathName);
  if (rawCurveInfo == null) {
    throw new Error("Path name " + pathName + " is not defined in " + curvePathsFile);
  }
  curveInfos.type = rawCurveInfo.getString("type");
  curveInfos.path = rawCurveInfo.getString("path");
  return curveInfos;
}

void loadVariables(Sequence sequence) {
  boolean initialise = sequence.isAtFirstRepeat() && sequence.isAtFirstStep();
  String variablesPathName = sequence.currentStep();
  JSONObject variablesPaths = loadJSONObject("config/paths/variablesPaths.json");
  String variablesPath = variablesPaths.getString(variablesPathName);

  JSONObject variables = loadJSONObject(variablesPath);
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

    String curveName = trailVariables.getString("curveName");
    CurveInfos curveInfos = loadCurveInfos(curveName);
    String curveType = curveInfos.type;
    String curvePath = curveInfos.path;

    // TODO: optimise curve load (load once for trails with same curve)
    ResampleConfig resampleConfig = new ResampleConfig();
    resampleConfig.resample = trailVariables.getBoolean("resample");
    resampleConfig.resampleRegular = trailVariables.getBoolean("resampleRegular");
    resampleConfig.resampleLen = trailVariables.getInt("resampleLen");

    if (curveType.equals("STROK_CURVE")) {
      HashMap<String, Vec2D[]> curves = loadStrokCurves(curvePath, resampleConfig);
      renderer.headPositions = curves.get("headCurve");
      renderer.tailPositions = curves.get("tailCurve");
    } else {
      renderer.singleCurve = loadSingleCurve(curvePath, resampleConfig);
    }

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
  JSONObject backgroundImageInfos = variables.getJSONObject("backgroundImage");
  if (
    initialise &&
    backgroundImageInfos != null &&
    backgroundImageInfos.getBoolean("use") == true
  ) {
    String bgImagePathName = backgroundImageInfos.getString("pathName");
    JSONObject imagePaths = loadJSONObject("config/paths/imagePaths.json");
    String imagePath = imagePaths.getString(bgImagePathName);
    BACKGROUND_IMAGE = loadImage(imagePath);
  }

  JSONArray backgroundColor = variables.getJSONArray("backgroundColor");
  for (int i = 0; i < BACKGROUND_COLOR.length; i++) {
    BACKGROUND_COLOR[i] = backgroundColor.getInt(i);
  }
}

Sequence loadSequence() {
  JSONObject config = loadJSONObject("config/config.json");
  JSONArray steps = config.getJSONArray("steps");
  int repeat = config.getInt("repeat");
  return new Sequence(steps, repeat == 0 ? 1 : repeat);
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

  for (TrailRenderer renderer: TRAIL_RENDERERS) {
    randomSeed(SEED);
    renderer.init(
      physics,
      realScale,
      layer1
    );
  }

  layer1.beginDraw();
  layer1.clear();
  if (BACKGROUND_IMAGE != null) {
    layer1.image(BACKGROUND_IMAGE, 0, 0, layer1.width, layer1.height);
  }
  // layer1.blendMode(BLEND);
  layer1.endDraw();
}

void recordVideo() {
  noLoop();
  while (videoFrameCount < VIDEO_NUM_FRAMES) {
    println("VIDEO: rendering frame " + videoFrameCount);
    float editStartTime = millis();
    for (TrailRenderer renderer: TRAIL_RENDERERS) {
      renderer.angleVariability += VIDEO_ANGLE_INCREMENT;
      renderer.minRadiusFactor += VIDEO_RADIUS_INCREMENT;
      renderer.maxRadiusFactor += VIDEO_RADIUS_INCREMENT;
    }
    float editEndTime = millis();
    println("VIDEO: renderer config duration " + ((editEndTime - editStartTime) / 1000) + " sec");
    float renderStartTime = millis();
    init();
    while (!allTrailRenderersFinished()) {
      newStep();
    }
    float renderDuration = millis() - renderStartTime;
    println("VIDEO: frame " + videoFrameCount + " saved, duration " + (renderDuration / 1000) + " sec");
    float saveStartTime = millis();
    saveLayerAsVideoFrame(layer1);
    float saveEndTime = millis();
    println("VIDEO: image save duration " + ((saveEndTime - saveStartTime) / 1000) + " sec");
    videoFrameCount++;
  }
}

void setup() {
  surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  size(500, 1000);
  smooth();
  physics = new VerletPhysics2D();
  SEQUENCE = loadSequence();
  loadVariables(SEQUENCE);
  init();

  if (OUTPUT == Output.VIDEO) {
    recordVideo();
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
  saveFrame(IMAGE_OUTPUT_FOLDER + "seed-"+SEED+"_date-"+ date + "_time-"+ time + ".tif");
}

void saveLayer(PGraphics layer, String layerName) {
  int date = (year() % 100) * 10000 + month() * 100 + day();
  int time = hour() * 10000 + minute() * 100 + second();
  layer.save(IMAGE_OUTPUT_FOLDER + "layer-" + layerName + "_seed-" + SEED + "_date-" + date + "_time-" + time + ".tif");
}

void printComposition(String outputFolder, String dateTime) {
  String fileName = dateTime + "-composition.tif";
  printLayer.beginDraw();
  printLayer.clear();
  printLayer.background(BACKGROUND_COLOR[0], BACKGROUND_COLOR[1], BACKGROUND_COLOR[2]);
  printLayer.image(layer1, 0, 0, printLayer.width, printLayer.height);
  printLayer.endDraw();
  printLayer.save(outputFolder + fileName);
}

void saveLayerAsVideoFrame(PGraphics layer) {
  layer.save("video/frame" + String.format("%04d", videoFrameCount) + ".tif");
}

String getDateTime() {
  String date = "" + year() + String.format("%02d", month()) + String.format("%02d", day());
  String time = String.format("%02d", hour()) + String.format("%02d", minute()) + String.format("%02d", second());
  return date + "_" + time;
}

void keyPressed() {
  int number = randomInt(0, 100);
  if (key == ' ') {
    saveLayer(layer1, "1");
  }
  if (key == 's' || key == 'p') {
    String dateTime = getDateTime();
    String outputFolder = IMAGE_OUTPUT_FOLDER + dateTime + "/";
    // save composition
    printComposition(outputFolder, dateTime);
    // save commit hash
    exec(sketchPath() + "/saveGitHash.sh", outputFolder);
    // save variables
    JSONObject variables = loadJSONObject("config/defaults/variables.json");
    saveJSONObject(variables, outputFolder + "variables.json");
    JSONArray trails = variables.getJSONArray("trails");
    for (int i = 0; i < trails.size(); i++) {
      JSONObject trailVariables = trails.getJSONObject(i);
      String curveName = trailVariables.getString("curveName");
      CurveInfos curveInfos = loadCurveInfos(curveName);
      String curveType = curveInfos.type;
      String curvePath = curveInfos.path;
      // save strok or single
      if (curveType.equals("STROK_CURVE")) {
        JSONObject namedCurves = loadJSONObject(curvePath);
        saveJSONObject(namedCurves, outputFolder + curveName + "_namedCurves.json");
      } else {
        JSONArray rawCurve = loadJSONArray(curvePath);
        saveJSONArray(rawCurve, outputFolder + curveName + "_singleCurve.json");
      }
    }
  }
  if (key == 'l') {
    BACKGROUND_IMAGE = null;
    SEQUENCE = loadSequence();
    clear();
    loadVariables(SEQUENCE);
    init();
  }
}

void newStep() {
  if (SEQUENCE.finished()) {
    return;
  }
  physics.update();
  layer1.beginDraw();
  layer1.scale(LAYER_SCALE);
  // rendering steps
  for (TrailRenderer renderer: TRAIL_RENDERERS) {
    renderer.render();
  }
  layer1.endDraw();
  if (allTrailRenderersFinished()) {
    SEQUENCE.next();
    if (!SEQUENCE.finished()) {
      BACKGROUND_IMAGE = layer1;
      clear();
      loadVariables(SEQUENCE);
      init();
    }
  }
}
