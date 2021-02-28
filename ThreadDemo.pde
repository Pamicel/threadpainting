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
boolean headTouchedLimit = false;
boolean tailTouchedLimit = false;

Vec2D headStartPos;
Vec2D tailStartPos;

int stage () {
  if (headTouchedLimit && tailTouchedLimit) {
    return 1;
  }
  return 0;
}

Vec2D stepVec(Vec2D head, Vec2D tail, int numParticles) {
  return tail.sub(head).normalizeTo(head.distanceTo(tail) / numParticles);
}

void setup() {
  size(1500,800);
  smooth();
  physics = new VerletPhysics2D();

  headStartPos = new Vec2D(- width / 10, height / 3);
  tailStartPos = new Vec2D(- width / 10, 2 * height / 3);

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
  float speedA = 0.4;
  float speedB = 0.3;

  if (stage() == 0 && !headTouchedLimit) {
    Vec2D headVelocity = new Vec2D(speedA * 5, speedA * - .5);
    head.set(head.x + headVelocity.x, head.y + headVelocity.y);
    if (head.x > X_LIMIT) {
      headTouchedLimit = true;
    }
  } else if (stage() == 1) {
    Vec2D headVelocity = new Vec2D(speedB * - 3, speedB * 5);
    head.set(head.x + headVelocity.x, head.y + headVelocity.y);
  }

  if (stage() == 0 && !tailTouchedLimit) {
    Vec2D tailVelocity = new Vec2D(speedA * 6, speedA * .5);
    tail.set(tail.x + tailVelocity.x, tail.y + tailVelocity.y);
    if (tail.x > X_LIMIT) {
      tailTouchedLimit = true;
    }

  } else if (stage() == 1) {
    Vec2D tailVelocity = new Vec2D(speedB * - .6, speedB * 6);
    tail.set(tail.x + tailVelocity.x, tail.y + tailVelocity.y);
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
   saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
