class Globals {
  Output output;
  int videoNumFrames;

  Globals(
    Output output,
    int videoNumFrames
  ) {
    this.output = output;
    this.videoNumFrames = videoNumFrames;
  }
}
// String curvePathsFile;
// String imagePathsFile;
// String scenePathsFile;

String getDateTime() {
  String date = "" + year() + String.format("%02d", month()) + String.format("%02d", day());
  String time = String.format("%02d", hour()) + String.format("%02d", minute()) + String.format("%02d", second());
  return date + "_" + time;
}

class CurveInfos {
  String path;
  String type;
  CurveInfos() {};
}

class SketchMemory {
  String globalConfigPath = "config/config.json";
  String sequenceConfigPath = "config/config.json";
  SceneConfig currentSceneConfig;
  PGraphics printLayer;
  int videoFrameCount;

  SketchMemory() {
    this.videoFrameCount = 0;
    this.printLayer = createGraphics(realWidth, realHeight);
  }

  Globals loadGlobals() {
    JSONObject config = loadJSONObject(this.globalConfigPath);

    int videoNumFrames = config.getInt("videoNumFrames");

    String outputType = config.getString("output");
    Output output = Output.DRAW;
    if (outputType.equals("VIDEO")) {
      output = Output.VIDEO;
    }

    return new Globals(
      output,
      videoNumFrames
    );
  }

  SequenceConfig loadSequenceConfig() {
    JSONObject config = loadJSONObject(this.sequenceConfigPath);

    int scenesRepeat = config.getInt("repeat");
    JSONArray scenes = config.getJSONArray("scenes");
    SequenceConfig sequenceConfig = new SequenceConfig();
    sequenceConfig.repeat = scenesRepeat == 0 ? 1 : scenesRepeat;
    sequenceConfig.scenes = scenes;
    return sequenceConfig;
  }

  private TrailRendererConfig serializeTrailConfig(JSONObject trailConfig) {
    TrailRendererConfig config = new TrailRendererConfig();

    config.minSpeedFactor = trailConfig.getFloat("minSpeedFactor");
    config.maxSpeedFactor = trailConfig.getFloat("maxSpeedFactor");
    config.nLinks = trailConfig.getInt("nLinks");
    config.strength = trailConfig.getFloat("strength");
    config.mass = MASS;
    config.angleVariability = trailConfig.getFloat("angleVariability");
    config.minRadiusFactor = trailConfig.getFloat("minRadiusFactor");
    config.maxRadiusFactor = trailConfig.getFloat("maxRadiusFactor");

    String curveName = trailConfig.getString("curveName");
    CurveInfos curveInfos = this.loadCurveInfos(curveName);
    String curveType = curveInfos.type;
    String curvePath = curveInfos.path;

    // TODO: optimise curve load (load once for trails with same curve)
    ResampleConfig resampleConfig = new ResampleConfig();
    resampleConfig.resample = trailConfig.getBoolean("resample");
    resampleConfig.resampleRegular = trailConfig.getBoolean("resampleRegular");
    resampleConfig.resampleLen = trailConfig.getInt("resampleLen");

    if (curveType.equals("STROK_CURVE")) {
      HashMap<String, Vec2D[]> curves = this.loadStrokCurves(curvePath, resampleConfig);
      config.headPositions = curves.get("headCurve");
      config.tailPositions = curves.get("tailCurve");
    } else {
      config.singleCurve = this.loadSingleCurve(curvePath, resampleConfig);
    }

    String widthFunctionName = trailConfig.getString("typeOfOverallShape");
    if (widthFunctionName.equals("FROM_SMALL")) {
      config.widthFunctionName = WidthFunctionName.FROM_SMALL;
    } else if (widthFunctionName.equals("TO_SMALL")) {
      config.widthFunctionName = WidthFunctionName.TO_SMALL;
    } else {
      config.widthFunctionName = WidthFunctionName.CONSTANT;
    }

    JSONArray trailColor = trailConfig.getJSONArray("trailColor");
    for (int colorIndex = 0; colorIndex < trailColor.size(); colorIndex++) {
      config.trailColor[colorIndex] = trailColor.getInt(colorIndex);
    }

    config.particleDiameterFactor = trailConfig.getFloat("particleDiamFactor");

    JSONArray renderingPipelineArray = trailConfig.getJSONArray("renderingPipeline");
    config.renderingStepNames = new String[renderingPipelineArray.size()];
    for (int stepIndex = 0; stepIndex < renderingPipelineArray.size(); stepIndex++) {
      config.renderingStepNames[stepIndex] = renderingPipelineArray.getString(stepIndex);
    }

    return config;
  }

  SceneConfig loadSceneConfig(String sceneFile) {
    return this.loadSceneConfig(sceneFile, false);
  }

  SceneConfig loadSceneConfig(String sceneFile, boolean initialScene) {
    JSONObject scenePaths = loadJSONObject("config/paths/scenePaths.json");
    String sceneFilePath = scenePaths.getString(sceneFile);
    JSONObject sceneObject = loadJSONObject(sceneFilePath);

    this.currentSceneConfig = new SceneConfig();

    this.currentSceneConfig.seed = sceneObject.getInt("seed");
    this.currentSceneConfig.updatesPerFrame = sceneObject.getInt("updatesPerFrame");

    JSONObject backgroundImageInfos = sceneObject.getJSONObject("backgroundImage");
    if (
      initialScene &&
      backgroundImageInfos != null &&
      backgroundImageInfos.getBoolean("use") == true
    ) {
      String bgImagePathName = backgroundImageInfos.getString("pathName");
      JSONObject imagePaths = loadJSONObject("config/paths/imagePaths.json");
      String imagePath = imagePaths.getString(bgImagePathName);
      // Save bg image
      this.currentSceneConfig.backgroundImage = loadImage(imagePath);
    }

    JSONArray backgroundColor = sceneObject.getJSONArray("backgroundColor");
    this.currentSceneConfig.backgroundColor = new int[backgroundColor.size()];
    for (int i = 0; i < backgroundColor.size(); i++) {
      this.currentSceneConfig.backgroundColor[i] = backgroundColor.getInt(i);
    }

    // Trails
    JSONArray trails = sceneObject.getJSONArray("trails");
    this.currentSceneConfig.trails = new TrailRendererConfig[trails.size()];
    for (int i = 0; i < trails.size(); i++) {
      this.currentSceneConfig.trails[i] = this.serializeTrailConfig(trails.getJSONObject(i));
    }

    return this.currentSceneConfig;
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

  HashMap<String, Vec2D[]> loadStrokCurves(
    String curvePath,
    ResampleConfig resampleConfig
  ) {
    JSONObject namedCurves = loadJSONObject(curvePath);
    JSONObject curveDescriptions = namedCurves.getJSONObject("curves");
    JSONArray rawHeadCurve = curveDescriptions.getJSONArray("headCurve");
    JSONArray rawTailCurve = curveDescriptions.getJSONArray("tailCurve");
    Vec2D[] headCurve = curveFromJSONArray(rawHeadCurve, LAYER_SCALE);
    Vec2D[] tailCurve = curveFromJSONArray(rawTailCurve, LAYER_SCALE);
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
    Vec2D[] curve = curveFromJSONArray(rawCurve, LAYER_SCALE);
    return applyResampleToCurve(curve, resampleConfig);
  }

  void saveCurrentFrame() {
    String date = getDateTime();
    saveFrame(IMAGE_OUTPUT_FOLDER + date + ".tif");
  }

  void saveLayer(PGraphics layer, String layerName) {
    String date = getDateTime();
    layer.save(IMAGE_OUTPUT_FOLDER + date + "_" + layerName + ".tif");
  }

  void saveComposition(
    String outputFolder,
    PGraphics canvasLayer,
    int[] backgroundColor
  ) {
    String fileName = getDateTime() + "-composition.tif";
    this.printLayer.beginDraw();
    this.printLayer.clear();
    this.printLayer.background(
      backgroundColor[0],
      backgroundColor[1],
      backgroundColor[2]
    );
    this.printLayer.image(canvasLayer, 0, 0, this.printLayer.width, this.printLayer.height);
    this.printLayer.endDraw();
    this.printLayer.save(outputFolder + fileName);
  }

  void saveLayerAsVideoFrame(PGraphics layer) {
    layer.save("video/frame" + String.format("%04d", videoFrameCount) + ".tif");
    this.videoFrameCount++;
  }
}