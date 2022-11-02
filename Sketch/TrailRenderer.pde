class TrailRenderer {
  float minSpeedFactor;
  float maxSpeedFactor;
  float minRadiusFactor;
  float maxRadiusFactor;
  int nLinks;
  float mass;
  float strength;
  float angleVariability;
  OverallShape typeOfOverallShape;
  int[] trailColor;
  float particleDiameterFactor;
  RenderingStep[] renderingPipeline;
  String[] renderingStepNames;
  ToxiColorTrail colorTrail;

  TrailRenderer() {
    this.trailColor = new int[3];
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

  void initFromCurve(
    VerletPhysics2D physics,
    Vec2D[] curve,
    int realScale,
    PGraphics layer,
    LayerVariables layerVars
  ) {
    this.colorTrail = ToxiColorTrailFromCurve(
      physics,
      curve,
      this.minSpeedFactor * realScale, this.maxSpeedFactor * realScale,
      this.minRadiusFactor * realScale, this.maxRadiusFactor * realScale,
      this.nLinks,
      this.mass,
      this.strength,
      this.angleVariability,
      this.typeOfOverallShape
    );

    this.instantiateRenderingPipeline(
      this.renderingStepNames,
      layer,
      layerVars
    );
  }

  void initFromStrok(
    VerletPhysics2D physics,
    Vec2D[] headPositions,
    Vec2D[] tailPositions,
    int realScale,
    PGraphics layer,
    LayerVariables layerVars
  ) {
    this.colorTrail = ToxiColorTrailFromStrok(
      physics,
      headPositions,
      tailPositions,
      this.minSpeedFactor * realScale, this.maxSpeedFactor * realScale,
      this.minRadiusFactor * realScale, this.maxRadiusFactor * realScale,
      this.nLinks,
      this.mass,
      this.strength,
      this.angleVariability
    );

    this.instantiateRenderingPipeline(
      this.renderingStepNames,
      layer,
      layerVars
    );
  }

  void instantiateRenderingPipeline(
    String[] renderingStepNames,
    PGraphics layer,
    LayerVariables layerVars
  ) {
    this.renderingPipeline = new RenderingStep[this.renderingStepNames.length];
    TrailRenderer renderer = this;
    for (int stepIndex = 0; stepIndex < renderingStepNames.length; stepIndex++) {
      if (renderingStepNames[stepIndex].equals("beads")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.display(
              layer,
              layerVars.rgbK,
              layerVars.baseColor,
              layerVars.rgbOffset,
              layerVars.omega,
              renderer.particleDiameterFactor,
              renderer.trailColor
            );
          }
        };
      } else if (renderingStepNames[stepIndex].equals("beadsWithoutExtremities")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayWithoutExtremities(
              layer,
              layerVars.rgbK,
              layerVars.baseColor,
              layerVars.rgbOffset,
              layerVars.omega,
              renderer.particleDiameterFactor,
              renderer.trailColor
            );
          }
        };
      } else if (renderingStepNames[stepIndex].equals("beadsOneInTwo")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayOneInTwo(
              layer,
              layerVars.rgbK,
              layerVars.baseColor,
              layerVars.rgbOffset,
              layerVars.omega,
              renderer.particleDiameterFactor,
              renderer.trailColor
            );
          }
        };
      } else if (renderingStepNames[stepIndex].equals("beadsStraight")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayStraight(
              layer,
              layerVars.rgbK,
              layerVars.baseColor,
              layerVars.rgbOffset,
              layerVars.omega,
              renderer.particleDiameterFactor,
              renderer.trailColor
            );
          }
        };
      } else if (renderingStepNames[stepIndex].equals("skeleton")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displaySkeleton(
              layer,
              renderer.particleDiameterFactor,
              renderer.trailColor
            );
          }
        };
      } else if (renderingStepNames[stepIndex].equals("displayPoints")) {
        renderingPipeline[stepIndex] = new RenderingStep() {
          void render() {
            colorTrail.colorString.displayPoints(
              layer,
              renderer.particleDiameterFactor,
              renderer.trailColor
            );
          }
        };
      }
    }
  }
}