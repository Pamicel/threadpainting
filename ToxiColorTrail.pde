class ToxiColorTrail {
  public Stage[] stages;
  private int headCurrentStage = 0;
  private int tailCurrentStage = 0;

  ToxiColorString colorString;
  VerletParticle2D head, tail;

  ToxiColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions,
    int numLinks,
    float mass,
    float strength,
    Vec3D rgbOffset
  ) {
    this.createColorTrail(
      physics,
      speeds,
      headPositions,
      tailPositions,
      numLinks,
      mass,
      strength,
      rgbOffset
    );
  }

  ToxiColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    ColorTrailTarget[] targets,
    int numLinks,
    float mass,
    float strength,
    Vec3D rgbOffset
  ) {
    Vec2D[] headPositions = new Vec2D[targets.length];
    Vec2D[] tailPositions = new Vec2D[targets.length];

    for (int i = 0; i < targets.length; i++) {
      headPositions[i] = targets[i].headPosition;
      tailPositions[i] = targets[i].tailPosition;
    }

    this.createColorTrail(
      physics,
      speeds,
      headPositions,
      tailPositions,
      numLinks,
      mass,
      strength,
      rgbOffset
    );
  }

  private void createColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions,
    int numLinks,
    float mass,
    float strength,
    Vec3D rgbOffset
  ) {
    this.createStages(
      speeds,
      headPositions,
      tailPositions
    );

    this.colorString = new ToxiColorString(physics, headPositions[0], tailPositions[0], numLinks, mass, strength, rgbOffset);
    this.head = colorString.head;
    this.tail = colorString.tail;
  }

  public int getCurrentStage () {
    return min(this.headCurrentStage, this.tailCurrentStage);
  }

  public boolean headFinished() {
    return this.headCurrentStage == this.stages.length;
  }

  public boolean tailFinished() {
    return this.tailCurrentStage == this.stages.length;
  }

  public boolean finished() {
    return this.getCurrentStage() == this.stages.length;
  }

  public void update () {
    if (this.finished()) {
      println("finished");
      return;
    }

    int currentStage = this.getCurrentStage();
    Vec2D currentHeadVelocity = this.stages[currentStage].headVelocity;
    Vec2D currentTailVelocity = this.stages[currentStage].tailVelocity;

    // Move head as long as it is in the current stage
    if (this.headCurrentStage == currentStage) {
      this.head.set(this.head.x + currentHeadVelocity.x, this.head.y + currentHeadVelocity.y);
      if (
        this.stages[currentStage].headOvershoot(this.head)
      ) {
        this.headCurrentStage = currentStage + 1;
        // Fix error cripping
        this.head.set(this.stages[currentStage].headPosTarget);
      }
    }
    // Move tail as long as it is in the current stage
    if (this.tailCurrentStage == currentStage) {
      this.tail.set(this.tail.x + currentTailVelocity.x, this.tail.y + currentTailVelocity.y);
      if (
        this.stages[currentStage].tailOvershoot(this.tail)
      ) {
        this.tailCurrentStage = currentStage + 1;
        // Fix error cripping
        this.tail.set(this.stages[currentStage].tailPosTarget);
      }
    }
  }

  private void createStages(
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions
  ) {
    if (headPositions.length != tailPositions.length) {
      throw new Error("must have as many head positions as tail positions");
    }
    if (speeds.length + 1 != headPositions.length) {
      throw new Error("Must have exactly one speed per section (3 positions -> 2 speeds, speed1 between point 1 and point 2 and speed 2 between point 2 and point 3)");
    }

    int numberOfStages = speeds.length;
    this.stages = new Stage[numberOfStages];
    for (int i = 0; i < numberOfStages; i++) {
      this.stages[i] = new Stage(
        // Origins
        new Vec2D[] {
          headPositions[i],
          tailPositions[i]
        },
        // Targets
        new Vec2D[] {
          headPositions[i + 1],
          tailPositions[i + 1]
        },
        // Speeds
        new float[] {
          speeds[i],
          speeds[i]
        }
      );
    }
  }
}