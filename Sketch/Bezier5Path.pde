class Bezier5Path {
  public Vec2D[] path;
  private Vec2D[] controlPoints;
  private int numSteps;

  Bezier5Path(Vec2D[] controlPoints, int numSteps) {
    if (controlPoints.length != 6) {
      throw new Error("Bezier of degree 5 requires 2 end points and 4 control points");
    }
    this.controlPoints = controlPoints;
    this.numSteps = numSteps;
    this.path = new Vec2D[numSteps + 1];

    Vec2D position;
    for (int i = 0; i < numSteps + 1; i++) {
      position = this.getPosition((float)i / numSteps);
      this.path[i] = position;
    }
  }

  Vec2D getPosition (float t) {
    if (t <= 0) {
      return this.controlPoints[0];
    } if (t >= 1) {
      return this.controlPoints[5];
    }

    float factor0 = pow((1 - t), 5);
    float factor1 = 5 * t * pow((1 - t), 4);
    float factor2 = 10 * pow(t, 2) * pow((1 - t), 3);
    float factor3 = 10 * pow(t, 3) * pow((1 - t), 2);
    float factor4 = 5 * pow(t, 4) * (1 - t);
    float factor5 = pow(t, 5);

    float x =
      factor0 * this.controlPoints[0].x
      + factor1 * this.controlPoints[1].x
      + factor2 * this.controlPoints[2].x
      + factor3 * this.controlPoints[3].x
      + factor4 * this.controlPoints[4].x
      + factor5 * this.controlPoints[5].x;

    float y =
      factor0 * this.controlPoints[0].y
      + factor1 * this.controlPoints[1].y
      + factor2 * this.controlPoints[2].y
      + factor3 * this.controlPoints[3].y
      + factor4 * this.controlPoints[4].y
      + factor5 * this.controlPoints[5].y;

    return new Vec2D(x, y);
  }

  void display() {
    for (int i = 0; i < this.numSteps + 1; i++) {
      ellipse(this.path[i].x, this.path[i].y, 8, 8);
    }
  }

  void displayControlPoints() {
    for (int i = 0; i < this.controlPoints.length; i++) {
      ellipse(this.controlPoints[i].x, this.controlPoints[i].y, 30, 30);
    }
  }
}