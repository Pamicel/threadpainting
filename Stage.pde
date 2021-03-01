class Stage {
  public Vec2D headPosOrigin, tailPosOrigin;
  public Vec2D headPosTarget, tailPosTarget;

  public float headSpeed, tailSpeed;
  public Vec2D headVelocity, tailVelocity;

  Stage(
    Vec2D[] origins,
    Vec2D[] targets,
    float[] speeds
  ) {
    this.headSpeed = speeds[0];
    this.tailSpeed = speeds[1];

    this.headPosOrigin = origins[0];
    this.tailPosOrigin = origins[1];

    this.headPosTarget = targets[0];
    this.tailPosTarget = targets[1];

    this.headVelocity = this.velocity(origins[0], targets[0], speeds[0]);
    this.tailVelocity = this.velocity(origins[1], targets[1], speeds[1]);
  }

  private Vec2D velocity(Vec2D origin, Vec2D target, float speed) {
    return target.sub(origin).normalizeTo(speed);
  }
  private boolean overshoot (Vec2D currentPos, Vec2D target, float speed) {
    return currentPos.isInCircle(target, 2 * speed);
  }

  boolean tailOvershoot(Vec2D tailCurrentPos) {
    return this.overshoot(tailCurrentPos, this.tailPosTarget, this.tailSpeed);
  }
  boolean headOvershoot(Vec2D headCurrentPos) {
    return this.overshoot(headCurrentPos, this.headPosTarget, this.headSpeed);
  }

  public void displayDebug() {
    push();
    noStroke();
    fill(255, 0, 0);
    ellipse(this.tailPosOrigin.x, this.tailPosOrigin.y, 5, 5);
    ellipse(this.tailPosTarget.x, this.tailPosTarget.y, 5, 5);
    ellipse(this.headPosOrigin.x, this.headPosOrigin.y, 5, 5);
    ellipse(this.headPosTarget.x, this.headPosTarget.y, 5, 5);
    noFill();
    stroke(255,0,0);
    strokeWeight(2);
    line(
      this.tailPosOrigin.x, this.tailPosOrigin.y,
      this.tailPosTarget.x, this.tailPosTarget.y
    );
    line(
      this.headPosOrigin.x, this.headPosOrigin.y,
      this.headPosTarget.x, this.headPosTarget.y
    );
    pop();
  }
}