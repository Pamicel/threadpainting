import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;
import java.util.Iterator;


VerletPhysics2D physics;

PGraphics CANVAS_LAYER;

enum Output { VIDEO, DRAW };
enum WidthFunctionName {TO_SMALL, FROM_SMALL, CONSTANT};

int realScale, realHeight, realWidth;

SketchMemory MEMORY;

Globals GLOBALS;
float LAYER_SCALE = .1;
int SCALE = 1;
int[] DEFAULT_BACKGROUND_COLOR = new int[]{0, 0, 0};

String IMAGE_OUTPUT_FOLDER = "out/";

// float VIDEO_ANGLE_INCREMENT = -0.01;
// float VIDEO_RADIUS_INCREMENT = 0;
// int VIDEO_NUM_FRAMES = 30;

float MASS = 1;
boolean SECONDARY_MONITOR = false;
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{0, 0};

Conductor CONDUCTOR;

/* */

// void recordVideo() {
//   noLoop();
//   while (videoFrameCount < VIDEO_NUM_FRAMES) {
//     println("VIDEO: rendering frame " + videoFrameCount);
//     float editStartTime = millis();
//     for (TrailRenderer renderer: TRAIL_RENDERERS) {
//       renderer.angleVariability += VIDEO_ANGLE_INCREMENT;
//       renderer.minRadiusFactor += VIDEO_RADIUS_INCREMENT;
//       renderer.maxRadiusFactor += VIDEO_RADIUS_INCREMENT;
//     }
//     float editEndTime = millis();
//     println("VIDEO: renderer config duration " + ((editEndTime - editStartTime) / 1000) + " sec");
//     float renderStartTime = millis();
//     initScene();
//     while (!allTrailRenderersFinished()) {
//       newStep();
//     }
//     float renderDuration = millis() - renderStartTime;
//     println("VIDEO: frame " + videoFrameCount + " saved, duration " + (renderDuration / 1000) + " sec");
//     float saveStartTime = millis();
//     saveLayerAsVideoFrame(canvasLayer);
//     float saveEndTime = millis();
//     println("VIDEO: image save duration " + ((saveEndTime - saveStartTime) / 1000) + " sec");
//     videoFrameCount++;
//   }
// }

void initialise() {
  GLOBALS = MEMORY.loadGlobals();
  CONDUCTOR = new Conductor(
    MEMORY,
    physics,
    CANVAS_LAYER
  );
}

void setup() {
  surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  size(500, 1000);
  smooth();
  physics = new VerletPhysics2D();
  realScale = SCALE;
  realWidth = width * realScale;
  realHeight = height * realScale;
  CANVAS_LAYER = createGraphics(realWidth, realHeight);
  MEMORY = new SketchMemory();
  initialise();

  // if (GLOBALS.output == Output.VIDEO) {
  //   recordVideo();
  // }
}

void draw() {
  int[] backgroundColor = CONDUCTOR.getBackgroundColor();
  background(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
  image(CANVAS_LAYER, 0, 0, width, height);
  if (CONDUCTOR.finished()) {
    return;
  }
  CONDUCTOR.draw();
}

void keyPressed() {
  if (key == ' ') {
    MEMORY.saveLayer(CANVAS_LAYER, "canvas");
  }
  if (key == 's' || key == 'p') {
    String dateTime = getDateTime();
    String outputFolder = IMAGE_OUTPUT_FOLDER + dateTime + "/";
    // save composition
    MEMORY.saveComposition(
      outputFolder,
      CANVAS_LAYER,
      CONDUCTOR.currentSceneConfig.backgroundColor
    );
    // save commit hash
    exec(sketchPath() + "/saveGitHash.sh", outputFolder);
    // save variables
    JSONObject variables = loadJSONObject("config/defaults/variables.json");
    saveJSONObject(variables, outputFolder + "variables.json");
    JSONArray trails = variables.getJSONArray("trails");
    for (int i = 0; i < trails.size(); i++) {
      JSONObject trailVariables = trails.getJSONObject(i);
      String curveName = trailVariables.getString("curveName");
      CurveInfos curveInfos = MEMORY.loadCurveInfos(curveName);
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
    CONDUCTOR.clear();
    initialise();
  }
}
