import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

// class ToxiColorString {
//   public VertelParticle2D head, tail;
//   public ParticleString2D pString;
//   public int numParticles;

//   public int headCurrentStage, tailCurrentStage;

//   private Vec2D headStartPos, tailStartPos;

//   ToxiColorString (
//     int numParticles,
//     float strength
//   ) {
//     this.headCurrentStage = 0;
//     this.tailCurrentStage = 0;
//   }

//   int stage () {
//     return min(this.headCurrentStage, this.tailCurrentStage);
//   }
// }

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
}

VerletPhysics2D physics;


int NUM_PARTICLES = 10;
VerletParticle2D head,tail;
ParticleString2D pString;

float STRENGTH = .0001;
int headCurrentStage = 0;
int tailCurrentStage = 0;

Vec2D headStartPos;
Vec2D tailStartPos;

int stage () {
  return min(headCurrentStage, tailCurrentStage);
}

Vec2D stepVec(Vec2D head, Vec2D tail, int numParticles) {
  return tail.sub(head).normalizeTo(head.distanceTo(tail) / (numParticles - 1));
}

float speedA = .4;
float speedB = .3;

Vec2D[] headPositions = new Vec2D[] {
  new Vec2D(-10, 300),
  new Vec2D(1000, 100),
  new Vec2D(1000, 1000)
};

Vec2D[] tailPositions = new Vec2D[] {
  new Vec2D(-10, 600),
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

// float[] headSpeeds = new float[] {
//   speedA,
//   speedB
// };

// float[] tailSpeeds = new float[] {
//   speedA,
//   speedB
// };

// Vec2D[] headPositions = new Vec2D[] {
//   new Vec2D(-10, 300),
//   new Vec2D(1000, 100),
//   new Vec2D(1000, 1000)
// };

// Vec2D[] tailPositions = new Vec2D[] {
//   new Vec2D(-10, 600),
//   new Vec2D(1000, 800),
//   new Vec2D(1500, 1000)
// };

// Vec2D velocity(Vec2D origin, Vec2D target, float speed) {
//   return target.sub(origin).normalizeTo(speed);
// }

// Vec2D headVelocity(int stage) {
//   return velocity(headPositions[stage], headPositions[stage + 1], headSpeeds[stage]);
// }

// Vec2D tailVelocity(int stage) {
//   return velocity(tailPositions[stage], tailPositions[stage + 1], tailSpeeds[stage]);
// }

// Vec2D[] headVelocities = new Vec2D[] {
//   // new Vec2D(speedA * 5, speedA * - .5),
//   // new Vec2D(speedB * - 3, speedB * 5)
//   headVelocity(0),
//   headVelocity(1)
// };

// Vec2D[] tailVelocities = new Vec2D[] {
//   // new Vec2D(speedA * 6, speedA * .5),
//   // new Vec2D(speedB * - .6, speedB * 6)
//   tailVelocity(0),
//   tailVelocity(1)
// };

// boolean tailOvershoot(int stage, Vec2D tail) {
//   return tail.isInCircle(tailPositions[stage + 1], 2 * tailSpeeds[stage]);
// }

// boolean headOvershoot(int stage, Vec2D head) {
//   return head.isInCircle(headPositions[stage + 1], 2 * headSpeeds[stage]);
// }

void setup() {
  size(1600,900);
  smooth();
  physics = new VerletPhysics2D();

  headStartPos = headPositions[0];
  tailStartPos = tailPositions[0];

  pString = new ParticleString2D(physics, headStartPos, stepVec(headStartPos, tailStartPos, NUM_PARTICLES), NUM_PARTICLES, 1, STRENGTH);
  head = pString.getHead();
  tail = pString.getTail();
  head.lock();
  tail.lock();
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
    headCurrentStage = currentStage + 1;
  }

  if (
    stages[currentStage].tailOvershoot(tail)
  ) {
    tailCurrentStage = currentStage + 1;
  }

  // // DEBUG
  // background(0);
  // stroke(255,100);
  // noFill();
  // beginShape();
  // for(Iterator i=physics.particles.iterator(); i.hasNext();) {
  //   VerletParticle2D p=(VerletParticle2D)i.next();
  //   vertex(p.x,p.y);
  // }
  // endShape();
  // // DEBUG

  Vec2D step = stepVec(head, tail, NUM_PARTICLES);
  Vec2D centerPos = head.copy().add(step.copy().normalizeTo(step.magnitude() / 2));

  Iterator particleIterator = pString.particles.iterator();
  VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();

  for(; particleIterator.hasNext();) {
    VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();

    Vec2D p = p1.interpolateTo(p2, 0.5);

    // Vec2D p = centerPos.copy();
    // centerPos = centerPos.add(step);

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
  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
