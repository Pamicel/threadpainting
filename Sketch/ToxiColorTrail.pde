class ColorTrailTarget {
  public Vec2D headPosition;
  public Vec2D tailPosition;

  ColorTrailTarget(
    Vec2D position,
    int radius,
    float angle
  ) {
    Vec2D radiusVector = new Vec2D(radius * cos(angle), radius * sin(angle));
    this.headPosition = position.copy().add(radiusVector);
    this.tailPosition = position.copy().sub(radiusVector);
  }
}

class ToxiColorTrail {
  public Step[] steps;
  private int headCurrentStep = 0;
  private int tailCurrentStep = 0;

  ToxiColorString colorString;
  VerletParticle2D head, tail;

  ToxiColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions,
    int numLinks,
    float mass,
    float strength
  ) {
    this.createColorTrail(
      physics,
      speeds,
      headPositions,
      tailPositions,
      numLinks,
      mass,
      strength
    );
  }

  ToxiColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    ColorTrailTarget[] targets,
    int numLinks,
    float mass,
    float strength
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
      strength
    );
  }

  private void createColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions,
    int numLinks,
    float mass,
    float strength
  ) {
    this.createSteps(
      speeds,
      headPositions,
      tailPositions
    );

    this.colorString = new ToxiColorString(physics, headPositions[0], tailPositions[0], numLinks, mass, strength);
    this.head = colorString.head;
    this.tail = colorString.tail;
  }

  public int getCurrentStep () {
    return min(this.headCurrentStep, this.tailCurrentStep);
  }

  public boolean headFinished() {
    return this.headCurrentStep == this.steps.length;
  }

  public boolean tailFinished() {
    return this.tailCurrentStep == this.steps.length;
  }

  public boolean finished() {
    return this.getCurrentStep() == this.steps.length;
  }

  public void backToOrigin() {
    this.head.set(this.steps[0].headPosTarget);
    this.tail.set(this.steps[0].tailPosTarget);
    this.headCurrentStep = 0;
    this.tailCurrentStep = 0;
  }

  public void update () {
    if (this.finished()) {
      return;
    }

    int currentStep = this.getCurrentStep();
    Vec2D currentHeadVelocity = this.steps[currentStep].headVelocity;
    Vec2D currentTailVelocity = this.steps[currentStep].tailVelocity;

    // Move head as long as it is in the current step
    if (this.headCurrentStep == currentStep) {
      this.head.set(this.head.x + currentHeadVelocity.x, this.head.y + currentHeadVelocity.y);
      if (
        this.steps[currentStep].headOvershoot(this.head)
      ) {
        this.headCurrentStep = currentStep + 1;
        // Fix error cripping
        this.head.set(this.steps[currentStep].headPosTarget);
      }
    }
    // Move tail as long as it is in the current step
    if (this.tailCurrentStep == currentStep) {
      this.tail.set(this.tail.x + currentTailVelocity.x, this.tail.y + currentTailVelocity.y);
      if (
        this.steps[currentStep].tailOvershoot(this.tail)
      ) {
        this.tailCurrentStep = currentStep + 1;
        // Fix error cripping
        this.tail.set(this.steps[currentStep].tailPosTarget);
      }
    }
  }

  private void createSteps(
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

    int numberOfSteps = speeds.length;
    this.steps = new Step[numberOfSteps];
    for (int i = 0; i < numberOfSteps; i++) {
      this.steps[i] = new Step(
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

ToxiColorTrail ToxiColorTrailFromPositions(
  VerletPhysics2D physics,
  Vec2D[] positions,
  float[] angles,
  float[] speeds,
  int[] radii,
  int nLinks,
  float mass,
  float strength
) {
  int numSteps = positions.length - 1;
  ColorTrailTarget[] targets = new ColorTrailTarget[numSteps + 1];

  for (int i = 0; i < numSteps + 1; i++) {
    targets[i] = new ColorTrailTarget(
      positions[i],
      radii[i],
      angles[i]
    );
  }


  return new ToxiColorTrail(
    physics,
    speeds,
    targets,
    nLinks, // Links
    mass, // Mass
    strength // Strength
  );
}

ToxiColorTrail ToxiColorTrailFromBezier(
  VerletPhysics2D physics,
  Bezier5Path bezier,
  float[] angles,
  float minSpeed,
  float maxSpeed,
  int minRadius,
  int maxRadius,
  int links,
  float mass,
  float strength
) {
  int numSteps = bezier.path.length - 1;
  float[] speeds = new float[numSteps];
  int[] radii = new int[numSteps];

  // create speeds
  for (int i = 0; i < numSteps; i++) {
    speeds[i] = random(minSpeed, maxSpeed);
    radii[i] = randomInt(minRadius, maxRadius);
  }

  // Make it shrink at the end
  radii[numSteps] = 0;

  return ToxiColorTrailFromPositions(
    physics,
    bezier.path,
    angles,
    speeds,
    radii,
    links,
    mass,
    strength
  );
}

ToxiColorTrail randomToxiColorTrail(
  VerletPhysics2D physics,
  Rect rectangle,
  float[] angles,
  float minSpeed,
  float maxSpeed,
  int minRadius,
  int maxRadius,
  int links,
  float mass,
  float strength
) {
  int numSteps = angles.length - 1;
  float[] speeds = new float[numSteps];
  ColorTrailTarget[] targets = new ColorTrailTarget[numSteps + 1];

  for (int i = 0; i < numSteps + 1; i++) {
    if (i < numSteps) {
      speeds[i] = random(minSpeed, maxSpeed);
    }

    targets[i] = new ColorTrailTarget(
      randomPosition(rectangle),
      randomInt(minRadius, maxRadius),
      angles[i]
    );
  }

  return new ToxiColorTrail(
    physics,
    speeds,
    targets,
    links, // Links
    mass, // Mass
    strength // Strength
  );
}