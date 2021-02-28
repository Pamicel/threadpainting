import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

int NUM_PARTICLES = 10;

VerletPhysics2D physics;
VerletParticle2D head,tail;
ParticleString2D pString;

int X_LIMIT = 1200; // px;
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

float speedA = 4;
float speedB = 3;

float[] headSpeeds = new float[] {
  speedA,
  speedB
};

float[] tailSpeeds = new float[] {
  speedA,
  speedB
};

Vec2D[] headPositions = new Vec2D[] {
  new Vec2D(50, 300),
  new Vec2D(1200, 100),
  new Vec2D(1000, 1000)
};

Vec2D[] tailPositions = new Vec2D[] {
  new Vec2D(50, 600),
  new Vec2D(1200, 800),
  new Vec2D(1500, 1000)
};

Vec2D headVelocity(int stage) {
  return headPositions[stage + 1].sub(headPositions[stage]).normalizeTo(headSpeeds[stage]);
}

Vec2D tailVelocity(int stage) {
  return tailPositions[stage + 1].sub(tailPositions[stage]).normalizeTo(tailSpeeds[stage]);
}

Vec2D[] headVelocities = new Vec2D[] {
  // new Vec2D(speedA * 5, speedA * - .5),
  // new Vec2D(speedB * - 3, speedB * 5)
  headVelocity(0),
  headVelocity(1)
};

Vec2D[] tailVelocities = new Vec2D[] {
  // new Vec2D(speedA * 6, speedA * .5),
  // new Vec2D(speedB * - .6, speedB * 6)
  tailVelocity(0),
  tailVelocity(1)
};

boolean tailOvershoot(int stage, Vec2D tail) {
  return tail.isInCircle(tailPositions[stage + 1], 2 * tailSpeeds[stage]);
}

boolean headOvershoot(int stage, Vec2D head) {
  return head.isInCircle(headPositions[stage + 1], 2 * headSpeeds[stage]);
}

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
  Vec2D currentHeadVelocity = headVelocities[currentStage];
  Vec2D currentTailVelocity = tailVelocities[currentStage];

  if (headCurrentStage == currentStage) {
    head.set(head.x + currentHeadVelocity.x, head.y + currentHeadVelocity.y);
  }
  if (tailCurrentStage == currentStage) {
    tail.set(tail.x + currentTailVelocity.x, tail.y + currentTailVelocity.y);
  }

  if (
    headOvershoot(currentStage, head)
  ) {
    headCurrentStage = currentStage + 1;
  }

  if (
    tailOvershoot(currentStage, tail)
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
    float k = .05;
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
