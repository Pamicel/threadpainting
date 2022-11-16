interface RenderingStep {
  void render();
};

class TrailRendererConfig {
  // Trajectory
  // Trajectory shape
  WidthFunctionName widthFunctionName;
  float minRadiusFactor;
  float maxRadiusFactor;
  float angleVariability;
  Vec2D[] headPositions;
  Vec2D[] tailPositions;
  Vec2D[] singleCurve;
  // Trajectory behaviour
  float minSpeedFactor;
  float maxSpeedFactor;
  // Brush
  int nLinks;
  float mass;
  float strength;
  int[] trailColor;
  float particleDiameterFactor;
  String[] renderingStepNames;
  // RandomSeed
  int seed;

  TrailRendererConfig() {
    this.trailColor = new int[3];
  }
}

class TrailRenderer {
  RenderingStep[] renderingPipeline;
  TrailRendererConfig config;
  ToxiColorTrail colorTrail;

  TrailRenderer(TrailRendererConfig config) {
    this.config = config;
  }

  void clear() {
    if (this.colorTrail != null) {
      this.colorTrail.clear();
    }
  }

  void render() {
    if (this.colorTrail.finished()) {
      return;
    }
    this.colorTrail.update();
    for (RenderingStep step : this.renderingPipeline) {
      step.render();
    }
  }

  boolean finished() {
    return this.colorTrail.finished();
  }

  private boolean isStrok() {
    return (
      this.config.headPositions != null &&
      this.config.tailPositions != null
    );
  }

  private boolean isSingleCurve() {
    return this.config.singleCurve != null;
  }

  void init(
    VerletPhysics2D physics,
    int realScale,
    PGraphics layer
  ) {
    if (this.isStrok()) {
      initFromStrok(
        physics,
        realScale,
        layer
      );
    } else if (this.isSingleCurve()) {
      initFromCurve(
        physics,
        realScale,
        layer
      );
    }
  }

  private void initFromCurve(
    VerletPhysics2D physics,
    int realScale,
    PGraphics layer
  ) {
    TrailRendererConfig config = this.config;
    this.colorTrail = ToxiColorTrailFromCurve(
      physics,
      config.singleCurve,
      config.minSpeedFactor * realScale, config.maxSpeedFactor * realScale,
      config.minRadiusFactor * realScale, config.maxRadiusFactor * realScale,
      config.nLinks,
      config.mass,
      config.strength,
      config.angleVariability,
      config.widthFunctionName
    );

    this.instantiateRenderingPipeline(layer);
  }

  private void initFromStrok(
    VerletPhysics2D physics,
    int realScale,
    PGraphics layer
  ) {
    TrailRendererConfig config = this.config;
    this.colorTrail = ToxiColorTrailFromStrok(
      physics,
      config.headPositions,
      config.tailPositions,
      config.minSpeedFactor * realScale, config.maxSpeedFactor * realScale,
      config.minRadiusFactor * realScale, config.maxRadiusFactor * realScale,
      config.nLinks,
      config.mass,
      config.strength,
      config.angleVariability,
      config.widthFunctionName
    );

    this.instantiateRenderingPipeline(layer);
  }

  void instantiateRenderingPipeline(PGraphics layer) {
    TrailRendererConfig config = this.config;
    int numRenderingSteps = config.renderingStepNames.length;
    this.renderingPipeline = new RenderingStep[numRenderingSteps];

    for (int stepIndex = 0; stepIndex < numRenderingSteps; stepIndex++) {
      if (config.renderingStepNames[stepIndex].equals("beads")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.display(
              layer,
              config.particleDiameterFactor,
              config.trailColor
            );
          }
        };
      } else if (config.renderingStepNames[stepIndex].equals("beadsWithoutExtremities")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayWithoutExtremities(
              layer,
              config.particleDiameterFactor,
              config.trailColor
            );
          }
        };
      } else if (config.renderingStepNames[stepIndex].equals("beadsOneInTwo")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayOneInTwo(
              layer,
              config.particleDiameterFactor,
              config.trailColor
            );
          }
        };
      } else if (config.renderingStepNames[stepIndex].equals("beadsStraight")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayStraight(
              layer,
              config.particleDiameterFactor,
              config.trailColor
            );
          }
        };
      } else if (config.renderingStepNames[stepIndex].equals("skeleton")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displaySkeleton(
              layer,
              config.particleDiameterFactor,
              config.trailColor
            );
          }
        };
      } else if (config.renderingStepNames[stepIndex].equals("displayPoints")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayPoints(
              layer,
              config.particleDiameterFactor,
              config.trailColor
            );
          }
        };
      }
    }
  }
}