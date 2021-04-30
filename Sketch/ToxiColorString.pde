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
    float omega
  ) {
    // float alph = 100.0;
    // float r = baseColor[0] * ((1 + cos((TWO_PI / rgbK[0]) * diam - omega + rgbOffset[0])) / 2);
    // float g = baseColor[1] * ((1 + cos((TWO_PI / rgbK[1]) * diam - omega + rgbOffset[1])) / 2);
    // float b = baseColor[2] * ((1 + cos((TWO_PI / rgbK[2]) * diam - omega + rgbOffset[2])) / 2);

    layer.push();
    // layer.stroke(r,g,b,alph);
    layer.stroke(255);
    layer.point(position.x, position.y);
    layer.pop();

    // for(float d = diam; d > 1; d -= 2) {
    //   layer.noFill();
    //   layer.stroke(r,g,b,alph);
    //   layer.strokeWeight(1);
    //   float angle = random(-2, 1);
    //   layer.arc(position.x, position.y, d, d, angle, angle + random(2, 3), OPEN);
    // }
  }

  public void display (PGraphics layer, float[] rgbK, int[] baseColor, float[] rgbOffset, float omega) {
    Iterator particleIterator = this.pString.particles.iterator();

    // Initialize
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();
    //
    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();
      Vec2D p = p1.interpolateTo(p2, 0.5);
      float diam = p1.distanceTo(p2);

      this.displayParticle(
        layer,
        p,
        diam,
        rgbK,
        baseColor,
        rgbOffset,
        omega
      );

      p1 = p2;
    }
  }

  public void displayOneInTwo (PGraphics layer, float[] rgbK, int[] baseColor, float[] rgbOffset, float omega) {
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

      float diam = p1.distanceTo(p2);

      this.displayParticle(
        layer,
        p,
        diam,
        rgbK,
        baseColor,
        rgbOffset,
        omega
      );
    }
  }

  public void displayStraight (PGraphics layer, float[] rgbK, int[] baseColor, float[] rgbOffset, float omega) {
    Vec2D step = stepVec(this.head, this.tail, this.numLinks);
    Vec2D centerPos = this.head.copy().add(step.copy().normalizeTo(step.magnitude() / 2));

    Iterator particleIterator = pString.particles.iterator();
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();

    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = centerPos.copy();
      centerPos = centerPos.add(step);

      float diam = p1.distanceTo(p2);

      this.displayParticle(
        layer,
        p,
        diam,
        rgbK,
        baseColor,
        rgbOffset,
        omega
      );

      p1 = p2;
    }
  }

  public void displaySkeleton() {
    stroke(255,100);
    noFill();
    beginShape();
    for(Iterator i=this.pString.particles.iterator(); i.hasNext();) {
      VerletParticle2D p=(VerletParticle2D)i.next();
      vertex(p.x,p.y);
    }
    endShape();
  }

  public void debugHead() {
    push();
    noStroke();
    fill(255, 0, 0);
    ellipse(this.head.x, this.head.y, 5, 5);
    pop();
  }

  public void debugTail() {
    push();
    noStroke();
    fill(255, 0, 0);
    ellipse(this.tail.x, this.tail.y, 5, 5);
    pop();
  }
}