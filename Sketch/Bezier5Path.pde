class Path {
  Vec2D[] path;

  Path(Vec2D[] path) {
    this.path = path;
  }

  Path translated(Vec2D trans) {
    Vec2D[] newPath = new Vec2D[this.path.length];
    for (int i = 0; i < this.path.length; i++) {
      newPath[i] = this.path[i].add(trans);
    }
    return new Path(newPath);
  }

  void translate(Vec2D trans) {
    Vec2D[] newPath = new Vec2D[this.path.length];
    for (int i = 0; i < this.path.length; i++) {
      newPath[i] = this.path[i].add(trans);
    }

    this.path = newPath;
  }

  void translate(float x, float y) {
    this.translate(new Vec2D(x, y));
  }

  void display() {
    for (int i = 0; i < this.path.length; i++) {
      ellipse(this.path[i].x, this.path[i].y, 8, 8);
    }
  }
}

class Bezier5Path extends Path {
  private Vec2D[] controlPoints;

  Bezier5Path(Vec2D[] controlPoints, int numSteps) {
    super(new Vec2D[numSteps + 1]);
    if (controlPoints.length != 6) {
      throw new Error("Bezier of degree 5 requires 2 end points and 4 control points");
    }
    this.controlPoints = controlPoints;

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

  void displayControlPoints() {
    for (int i = 0; i < this.controlPoints.length; i++) {
      ellipse(this.controlPoints[i].x, this.controlPoints[i].y, 30, 30);
    }
  }
}

class GreatFeather extends Path {
  GreatFeather(float size, int nSegmentsLine, int nSegmentsBezier) {
    super(new Vec2D[nSegmentsLine + nSegmentsBezier + 1]);
    float scaleFactor = size / 2;
    // First point at origin
    this.path[0] = new Vec2D(0, 0);

    // Line
    Vec2D target = new Vec2D(0, scaleFactor);
    Vec2D increment = target.copy().sub(this.path[0]).scale(1.0 / nSegmentsLine);
    for (int i = 1; i < nSegmentsLine; i++) {
      this.path[i] = this.path[i - 1].copy().add(increment);
    }

    // Bezier
    Vec2D startingPoint = new Vec2D(0, 0);
    float curveSquishFactor = 17.0 / 12.0;
    float wFactor = scaleFactor * .9;
    float hFactor = scaleFactor * curveSquishFactor;

    Vec2D sidePoint = new Vec2D(wFactor, wFactor / 10);
    Vec2D point2 = startingPoint.copy().add(new Vec2D(wFactor + random(1, 10), wFactor / 3));
    Vec2D point5 = startingPoint.copy().add(new Vec2D(-wFactor - random(1, 10), wFactor / 3));

    Vec2D point3 = startingPoint.copy().add(0, hFactor).add(new Vec2D(wFactor, 0));
    Vec2D point4 = startingPoint.copy().add(0, hFactor).sub(new Vec2D(wFactor, 0));

    Bezier5Path bezier = new Bezier5Path(
      new Vec2D[] {
        startingPoint,
        point2,
        point3,
        point4,
        point5,
        startingPoint
      },
      nSegmentsBezier
    );

    bezier.translate(0, scaleFactor);

    for (int i = 0; i < bezier.path.length; i++) {
      this.path[nSegmentsLine + i] = bezier.path[i];
    }

    this.translate(0, - scaleFactor);
  }
}