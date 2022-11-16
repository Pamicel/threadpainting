class SceneConfig {
  SceneConfig() {}
  TrailRendererConfig[] trails;
  int seed;
  int updatesPerFrame;
  PImage backgroundImage;
  int[] backgroundColor;
}

class SceneRenderer {
  TrailRenderer[] trailRenderers;
  SceneConfig config;

  SceneRenderer(SceneConfig config) {
    this.config = config;
    this.createTrailRenderers(this.config.trails);
  }

  void createTrailRenderers(TrailRendererConfig[] trailRendererConfigs) {
    this.trailRenderers = new TrailRenderer[trailRendererConfigs.length];
    for (int i = 0; i < trailRendererConfigs.length; i++) {
      TrailRendererConfig trailConfig = trailRendererConfigs[i];
      this.trailRenderers[i] = new TrailRenderer(trailConfig);
    }
  }

  void clear() {
    // Remove the color springs from the simulation
    if (this.trailRenderers != null) {
      for (TrailRenderer renderer: this.trailRenderers) {
        renderer.clear();
      }
    }
  }

  void setBackgroundImage(PImage img) {
    this.config.backgroundImage = img;
  }

  int[] getBackgroundColor() {
    return this.config.backgroundColor;
  }

  boolean finished() {
    boolean allFinished = true;
    for (TrailRenderer renderer: this.trailRenderers) {
      allFinished = allFinished && renderer.finished();
    }
    return allFinished;
  }

  void draw(PGraphics canvasLayer) {
    canvasLayer.beginDraw();
    canvasLayer.scale(LAYER_SCALE);
    for (TrailRenderer renderer: this.trailRenderers) {
      renderer.render();
    }
    canvasLayer.endDraw();
  }

  void init(
    VerletPhysics2D physics,
    int realScale,
    PGraphics canvasLayer
  ) {
    for (TrailRenderer renderer: this.trailRenderers) {
      randomSeed(this.config.seed);
      renderer.init(
        physics,
        realScale,
        canvasLayer
      );
    }

    canvasLayer.beginDraw();
    canvasLayer.clear();
    if (this.config.backgroundImage != null) {
      canvasLayer.image(
        this.config.backgroundImage,
        0, 0,
        canvasLayer.width,
        canvasLayer.height
      );
    }
    // canvasLayer.blendMode(BLEND);
    canvasLayer.endDraw();
  }
}

class Conductor {
  Sequence sequence;
  SceneConfig currentSceneConfig;
  SceneRenderer sceneRenderer;
  SketchMemory memory;
  VerletPhysics2D physics;
  PGraphics canvasLayer;

  Conductor(
    SketchMemory memory,
    VerletPhysics2D physics,
    PGraphics canvasLayer
  ) {
    this.sequence = new Sequence(memory.loadSequenceConfig());
    this.memory = memory;
    this.physics = physics;
    this.canvasLayer = canvasLayer;
    this.loadScene();
  }

  int[] getBackgroundColor() {
    if (this.sceneRenderer != null) {
      return this.sceneRenderer.config.backgroundColor;
    }
    return DEFAULT_BACKGROUND_COLOR;
  }

  void loadScene() {
    String currentSceneName = this.sequence.currentScene();
    boolean isInitialScene = this.sequence.isAtFirstRepeat() && this.sequence.isAtFirstScene();
    // Remove all trails from the simulation
    if (this.sceneRenderer != null) {
      this.sceneRenderer.clear();
    }
    this.currentSceneConfig = this.memory.loadSceneConfig(currentSceneName, isInitialScene);
    this.sceneRenderer = new SceneRenderer(this.currentSceneConfig);
    if (!isInitialScene) {
      this.sceneRenderer.setBackgroundImage(this.canvasLayer.copy());
    }
    this.sceneRenderer.init(
      this.physics,
      SCALE,
      this.canvasLayer
    );
  }

  void clear() {
    this.sceneRenderer.clear();
  }

  boolean finished() {
    return this.sequence.finished();
  }

  void draw() {
    for(int i = 0; i < this.currentSceneConfig.updatesPerFrame; i++) {
      this.render();
    }
  }

  void render() {
    if (this.sequence.finished()) {
      return;
    }
    this.physics.update();
    this.sceneRenderer.draw(this.canvasLayer);
    if (this.sceneRenderer.finished()) {
      this.sequence.next();
      this.loadScene();
    }
  }
}
