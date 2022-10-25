float smoothstep (float edge0, float edge1, float x) {
   if (x < edge0)
      return 0;
   if (x >= edge1)
      return 1;
   // Scale/bias into [0..1] range
   x = (x - edge0) / (edge1 - edge0);
   return x * x * (3 - 2 * x);
}

class ToxiColorString {
  public VerletParticle2D head, tail;
  public ParticleString2D pString;
  public int numParticles;
  public int numLinks;

  ToxiColorString (
    VerletPhysics2D physics,
    Vec2D headStartPos,
    Vec2D tailStartPos,
    int numLinks,
    float mass,
    float strength
  ) {
    this.numLinks = numLinks;
    numParticles = numLinks + 1;

    Vec2D stepVector = this.stepVec(headStartPos, tailStartPos, numLinks);

    this.pString = new ParticleString2D(
      physics,
      headStartPos,
      stepVector,
      numParticles,
      mass,
      strength
    );


    this.head = pString.getHead();
    this.tail = pString.getTail();

    head.lock();
    tail.lock();
  }

  void clear() {
    this.pString.clear();
  }

  private Vec2D stepVec(Vec2D headPos, Vec2D tailPos, int numLinks) {
    return tailPos.sub(headPos).normalizeTo(headPos.distanceTo(tailPos) / numLinks);
  }

  private void displayParticle (
    PGraphics layer,
    Vec2D position,
    float diam,
    float[] rgbK,
    int[] baseColor,
    float[] rgbOffset,
    float omega,
    int[] col,
    float cycleProgress
  ) {
    float alph = 100.0;
    // float r = baseColor[0] + 255 * smoothstep(.04, .2, (diam * layerScale) / layer.width);
    // float g = baseColor[1] + 255 * smoothstep(.04, .2, (diam * layerScale) / layer.width);
    // float b = baseColor[2] + 255 * smoothstep(.04, .2, (diam * layerScale) / layer.width);
    // float alph = 100.0;
    layer.noStroke();
    layer.fill(col[0], col[1], col[2], alph);
    layer.ellipse(position.x,position.y,diam,diam);
  }

  private void displayParticle (
    PGraphics layer,
    Vec2D position,
    float diam,
    float[] rgbK,
    int[] baseColor,
    float[] rgbOffset,
    float omega,
    int[] col
  ) {
    displayParticle(
      layer,
      position,
      diam,
      rgbK,
      baseColor,
      rgbOffset,
      omega,
      col,
      0.0
    );
  }

  public void display (
    PGraphics layer,
    float[] rgbK,
    int[] baseColor,
    float[] rgbOffset,
    float omega,
    float diamFactor,
    int[] col,
    float cycleProgress
  ) {
    Iterator particleIterator = this.pString.particles.iterator();

    // Initialize
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();
    //
    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();
      Vec2D p = p1.interpolateTo(p2, 0.5);
      float diam = p1.distanceTo(p2) * diamFactor;

      this.displayParticle(
        layer,
        p,
        diam,
        rgbK,
        baseColor,
        rgbOffset,
        omega,
        col,
        cycleProgress
      );

      p1 = p2;
    }
  }

  public void display (
    PGraphics layer,
    float[] rgbK,
    int[] baseColor,
    float[] rgbOffset,
    float omega,
    float diamFactor,
    int[] col
  ) {
    this.display(
      layer,
      rgbK,
      baseColor,
      rgbOffset,
      omega,
      diamFactor,
      col,
      0.0
    );
  }

  public void displayOneInTwo (
    PGraphics layer,
    float[] rgbK,
    int[] baseColor,
    float[] rgbOffset,
    float omega,
    float diamFactor,
    int[] col
  ) {
    Iterator particleIterator = this.pString.particles.iterator();

    // Initialize
    //
    for(; particleIterator.hasNext();) {
      VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();

      if (!particleIterator.hasNext()) {
        break;
      }

      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = p1.interpolateTo(p2, 0.5);

      float diam = p1.distanceTo(p2) * diamFactor;

      this.displayParticle(
        layer,
        p,
        diam,
        rgbK,
        baseColor,
        rgbOffset,
        omega,
        col
      );
    }
  }

  public void displayStraight (
    PGraphics layer,
    float[] rgbK,
    int[] baseColor,
    float[] rgbOffset,
    float omega,
    float diamFactor,
    int[] col
  ) {
    Vec2D step = stepVec(this.head, this.tail, this.numLinks);
    Vec2D centerPos = this.head.copy().add(step.copy().normalizeTo(step.magnitude() / 2));

    Iterator particleIterator = pString.particles.iterator();
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();

    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = centerPos.copy();
      centerPos = centerPos.add(step);

      float diam = p1.distanceTo(p2) * diamFactor;

      this.displayParticle(
        layer,
        p,
        diam,
        rgbK,
        baseColor,
        rgbOffset,
        omega,
        col
      );

      p1 = p2;
    }
  }

  public void displaySkeleton(
    PGraphics layer,
    float diamFactor,
    int[] col
  ) {
    layer.stroke(col[0], col[1], col[2]);
    layer.strokeWeight(diamFactor * 10);
    layer.noFill();
    layer.beginShape();
    for(Iterator i=this.pString.particles.iterator(); i.hasNext();) {
      VerletParticle2D p=(VerletParticle2D)i.next();
      layer.vertex(p.x ,p.y);
    }
    layer.endShape();
  }

  public void displayPoints(
    PGraphics layer,
    float diamFactor,
    int[] col
  ) {
    layer.fill(col[0], col[1], col[2]);
    layer.noStroke();
    for(Iterator i=this.pString.particles.iterator(); i.hasNext();) {
      VerletParticle2D p=(VerletParticle2D)i.next();
      layer.ellipse(p.x,p.y, diamFactor * 20, diamFactor * 20);
    }
  }

  public void debugHead(
    PGraphics layer
  ) {
    layer.push();
    layer.noStroke();
    layer.fill(255, 0, 0);
    layer.ellipse(this.head.x, this.head.y, 20, 20);
    layer.pop();
  }

  public void debugTail(
    PGraphics layer
  ) {
    layer.push();
    layer.noStroke();
    layer.fill(255, 0, 0);
    layer.ellipse(this.tail.x, this.tail.y, 20, 20);
    layer.pop();
  }
}