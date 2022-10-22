class ColorTrailTarget {
  public Vec2D headPosition;
  public Vec2D tailPosition;
  public Vec2D position = null;
  public float angle;
  public int radius;
  public Vec2D radiusVector;

  ColorTrailTarget(
    Vec2D position,
    int radius,
    float angle
  ) {
    this.radiusVector = new Vec2D(radius * cos(angle + HALF_PI), radius * sin(angle + HALF_PI));
    this.headPosition = position.copy().add(this.radiusVector);
    this.tailPosition = position.copy().sub(this.radiusVector);
    this.radius = radius;
    this.angle = angle;
    this.position = position;
  }
}

class ToxiColorTrail {
  public Step[] steps;
  private int headCurrentStep = 0;
  private int tailCurrentStep = 0;

  ColorTrailTarget[] targets;
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
    this.targets = targets;

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

  public void displayTargets(PGraphics layer) {
    for (int i = 0; i < this.targets.length; i++) {
      layer.fill(0);
      layer.stroke(0);
      layer.strokeWeight(10);
      layer.ellipse(this.targets[i].headPosition.x, this.targets[i].headPosition.y, 20, 20);
      layer.ellipse(this.targets[i].tailPosition.x, this.targets[i].tailPosition.y, 20, 20);
      if (targets[i].position == null) {
        continue;
      }
      layer.pushMatrix();
      layer.translate(this.targets[i].position.x, this.targets[i].position.y);
      layer.line(0, 0, this.targets[i].radiusVector.x, this.targets[i].radiusVector.y);
      layer.line(0, 0, -this.targets[i].radiusVector.x, -this.targets[i].radiusVector.y);
      layer.rotate(this.targets[i].angle);
      layer.ellipse(0, 0, 20, 20);
      layer.line(0, 0, 200, 0);
      layer.popMatrix();
    }
  }

  public int getCurrentStep() {
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
  ColorTrailTarget[] targets = new ColorTrailTarget[numSteps + 1];

  for (int i = 0; i < numSteps + 1; i++) {
    if (i < numSteps) {
      speeds[i] = random(minSpeed, maxSpeed);
    }

    targets[i] = new ColorTrailTarget(
      bezier.path[i],
      randomInt(minRadius, maxRadius),
      angles[i]
    );
  }

  // override last
  targets[numSteps] = new ColorTrailTarget(
    bezier.path[numSteps],
    0,
    angles[numSteps]
  );


  return new ToxiColorTrail(
    physics,
    speeds,
    targets,
    links, // Links
    mass, // Mass
    strength // Strength
  );
}

ToxiColorTrail ToxiColorTrailFromCurve(
  VerletPhysics2D physics,
  Vec2D[] curve,
  float minSpeed,
  float maxSpeed,
  int minRadius,
  int maxRadius,
  int links,
  float mass,
  float strength,
  float angleVariability,
  OverallShape shape
) {
  int numTargetPoints = curve.length;
  int numSegments = numTargetPoints - 1;
  // Default radius factor is 1.0
  float radiusFactor = 1.0;
  // By default the radius factor is constant
  float radiusFactorIncrement = 0.0;
  if (shape == OverallShape.SMALL_TO_BIG) {
    // Set starting factor to 0.0
    radiusFactor = 0.0;
    // Increment every step
    radiusFactorIncrement = + 1.0 / numTargetPoints;
  } else if (shape == OverallShape.BIG_TO_SMALL) {
    // Set starting factor to 1.0
    radiusFactor = 1.0;
    // Decrement every step
    radiusFactorIncrement = - 1.0 / numTargetPoints;
  }

  ColorTrailTarget[] targets = new ColorTrailTarget[numTargetPoints];
  float[] speeds = new float[numSegments];
  int[] radii = new int[numTargetPoints];
  float[] angles = new float[numTargetPoints];
  for (int pointIndex = 0; pointIndex < numTargetPoints; pointIndex++) {
    // Angles
    float randomAngle = random(-PI, PI) * angleVariability;
    if (pointIndex < (numTargetPoints - 1)) {
      angles[pointIndex] = signedAngleBetweenVectors(new Vec2D(1, 0), curve[pointIndex + 1].sub(curve[pointIndex])) + randomAngle;
    } else {
      angles[pointIndex] = signedAngleBetweenVectors(new Vec2D(1, 0), curve[pointIndex].sub(curve[pointIndex - 1])) + randomAngle;
    }

    // Radii
    radiusFactor += radiusFactorIncrement;
    radii[pointIndex] = int(randomInt(minRadius, maxRadius) * radiusFactor);

    // Speeds
    if (pointIndex < numSegments) {
      speeds[pointIndex] = random(minSpeed, maxSpeed);
    }

    // Targets
    targets[pointIndex] = new ColorTrailTarget(
      curve[pointIndex],
      radii[pointIndex],
      angles[pointIndex]
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