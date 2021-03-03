class ToxiColorString {
  public VerletParticle2D head, tail;
  public ParticleString2D pString;
  public int numParticles;
  public int numLinks;
  Vec3D rgbOffset;

  ToxiColorString (
    VerletPhysics2D physics,
    Vec2D headStartPos,
    Vec2D tailStartPos,
    int numLinks,
    float mass,
    float strength,
    Vec3D rgbOffset
  ) {
    this.numLinks = numLinks;
    numParticles = numLinks + 1;
    this.rgbOffset = rgbOffset;

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

  public void display (float colorSpectrumWidth, float colorSpectrumOffset) {
    Iterator particleIterator = this.pString.particles.iterator();

    // Initialize
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();
    //
    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = p1.interpolateTo(p2, 0.5);

      float diam = p1.distanceTo(p2);
      float k = colorSpectrumWidth;
      float omega = colorSpectrumOffset;

      // float alph = (1 + cos(k * diam - omega)) * 50;
      float alph = 100.0;
      float r = abs(255 * cos(k * diam - omega + this.rgbOffset.x));
      float g = abs(255 * cos(k * diam - omega + this.rgbOffset.y));
      float b = abs(255 * cos(k * diam - omega + this.rgbOffset.z));
      // float alph = 100.0;
      fill(r,g,b,alph);
      ellipse(p.x,p.y,diam,diam);
      p1 = p2;
    }
  }

  public void displayOneInTwo (float colorSpectrumWidth, float colorSpectrumOffset) {
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
      float k = colorSpectrumWidth;
      float omega = colorSpectrumOffset;

      // float alph = (1 + cos(k * diam - omega)) * 50;
      float alph = 100.0;
      float r = abs(255 * cos(k * diam - omega + this.rgbOffset.x));
      float g = abs(255 * cos(k * diam - omega + this.rgbOffset.y));
      float b = abs(255 * cos(k * diam - omega + this.rgbOffset.z));
      // float alph = 100.0;
      fill(r,g,b,alph);
      ellipse(p.x,p.y,2*diam,2*diam);
    }
  }

  public void displayStraight (float colorSpectrumWidth, float colorSpectrumOffset) {
    Vec2D step = stepVec(this.head, this.tail, this.numLinks);
    Vec2D centerPos = this.head.copy().add(step.copy().normalizeTo(step.magnitude() / 2));

    Iterator particleIterator = pString.particles.iterator();
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();

    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = centerPos.copy();
      centerPos = centerPos.add(step);

      float diam = p1.distanceTo(p2);
      float k = colorSpectrumWidth;
      float omega = colorSpectrumOffset;

      // float alph = (1 + cos(k * diam - omega)) * 50;
      float alph = 100.0;
      float r = abs(255 * cos(k * diam - omega + this.rgbOffset.x));
      float g = abs(255 * cos(k * diam - omega + this.rgbOffset.y));
      float b = abs(255 * cos(k * diam - omega + this.rgbOffset.z));
      // float alph = 100.0;
      fill(r,g,b,alph);
      ellipse(p.x,p.y,diam,diam);
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