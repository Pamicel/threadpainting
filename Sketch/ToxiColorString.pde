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
    println("ToxiColorString - stepVector created");

    this.pString = new ParticleString2D(
      physics,
      headStartPos,
      stepVector,
      numParticles,
      mass,
      strength
    );

    println("ToxiColorString - ParticleString2D created");

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
    float alph = 100.0;
    float r = 0;
    float g = 0;
    float b = 0;

    // for(float d = diam; d > 1; d -= 2) {
      layer.fill(0);
      // layer.stroke(0);
      // layer.strokeWeight(diam / 10);
      layer.ellipse(position.x, position.y, diam, diam);
      // layer.line(position.x, position.y, position.x + diam, position.y + diam);
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