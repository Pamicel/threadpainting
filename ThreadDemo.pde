import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

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

  public void display () {
    Iterator particleIterator = this.pString.particles.iterator();

    // Initialize
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();
    //
    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = p1.interpolateTo(p2, 0.5);

      float diam = p1.distanceTo(p2);
      float k = .02;
      float omega = .5 * TWO_PI;

      Vec3D rgbOffset = new Vec3D(
        .1 * TWO_PI,
        .2 * TWO_PI,
        .3 * TWO_PI
      );
      // float alph = (1 + cos(k * diam - omega)) * 50;
      float alph = 100.0;
      float r = abs(255 * cos(k * diam - omega + rgbOffset.x));
      float g = abs(255 * cos(k * diam - omega + rgbOffset.y));
      float b = abs(255 * cos(k * diam - omega + rgbOffset.z));
      // float alph = 100.0;
      fill(r,g,b,alph);
      ellipse(p.x,p.y,diam,diam);
      p1 = p2;
    }
  }

  public void displayStraight () {
    Vec2D step = stepVec(this.head, this.tail, this.numLinks);
    Vec2D centerPos = this.head.copy().add(step.copy().normalizeTo(step.magnitude() / 2));

    Iterator particleIterator = pString.particles.iterator();
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();

    for(; particleIterator.hasNext();) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

      Vec2D p = centerPos.copy();
      centerPos = centerPos.add(step);

      float diam = p1.distanceTo(p2);
      float k = .02;
      float omega = .5 * TWO_PI;

      Vec3D rgbOffset = new Vec3D(
        .1 * TWO_PI,
        .2 * TWO_PI,
        .3 * TWO_PI
      );
      // float alph = (1 + cos(k * diam - omega)) * 50;
      float alph = 100.0;
      float r = abs(255 * cos(k * diam - omega + rgbOffset.x));
      float g = abs(255 * cos(k * diam - omega + rgbOffset.y));
      float b = abs(255 * cos(k * diam - omega + rgbOffset.z));
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
    for(Iterator i=physics.particles.iterator(); i.hasNext();) {
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

VerletPhysics2D physics;


int NUM_PARTICLES = 10;
float STRENGTH = .0001;
int headCurrentStage = 0;
int tailCurrentStage = 0;

int stage () {
  return min(headCurrentStage, tailCurrentStage);
}

float speedA = 4;
float speedB = 3;

Vec2D[] headPositions = new Vec2D[] {
  new Vec2D(-10, 300),
  new Vec2D(1000, 100),
  new Vec2D(1000, 1200)
};

Vec2D[] tailPositions = new Vec2D[] {
  new Vec2D(-10, 700),
  new Vec2D(1000, 800),
  new Vec2D(1500, 1000)
};

Stage stage1 =
  new Stage(
    // Origins
    new Vec2D[] {
      headPositions[0],
      tailPositions[0]
    },
    // Targets
    new Vec2D[] {
      headPositions[1],
      tailPositions[1]
    },
    // Speeds
    new float[] {
      speedA,
      speedA
    }
);

Stage stage2 =
  new Stage(
    // Origins
    new Vec2D[] {
      headPositions[1],
      tailPositions[1]
    },
    // Targets
    new Vec2D[] {
      headPositions[2],
      tailPositions[2]
    },
    // Speeds
    new float[] {
      speedA,
      speedA
    }
);

Stage[] stages = new Stage[] {
  stage1,
  stage2
};

ToxiColorString colorString;

void setup() {
  size(1600,900);
  smooth();
  physics = new VerletPhysics2D();

  headStartPos = stages[0].headPosOrigin;
  tailStartPos = stages[0].tailPosOrigin;

  colorString = new ToxiColorString(physics, headStartPos, tailStartPos, NUM_PARTICLES - 1, 1, STRENGTH);
  head = colorString.head;
  tail = colorString.tail;
  background(0);
  noStroke();
}

void draw() {
  physics.update();
  int currentStage = stage();
  Vec2D currentHeadVelocity = stages[currentStage].headVelocity;
  Vec2D currentTailVelocity = stages[currentStage].tailVelocity;

  if (headCurrentStage == currentStage) {
    head.set(head.x + currentHeadVelocity.x, head.y + currentHeadVelocity.y);
  }
  if (tailCurrentStage == currentStage) {
    tail.set(tail.x + currentTailVelocity.x, tail.y + currentTailVelocity.y);
  }

  if (
    stages[currentStage].headOvershoot(head)
  ) {
    headCurrentStage = min(stages.length - 1, currentStage + 1);
  }

  if (
    stages[currentStage].tailOvershoot(tail)
  ) {
    tailCurrentStage = min(stages.length - 1, currentStage + 1);
  }

  colorString.displayStraight();
  colorString.display();

  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
