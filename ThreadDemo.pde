/**
 * Thread demo showing the following:
 * - construction of a 2D string made from particles and springs/sticks using the ParticleString2D class
 * - dynamic locking & unlocking of particles
 *
 * Click the mouse to lock/unlock the end of the string at its current position.
 * The head of the string is always linked to the current mouse position
 *
 * @author Karsten Schmidt <info at postspectacular dot com>
 */

/*
 * Copyright (c) 2008-2009 Karsten Schmidt
 *
 * This demo & library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * http://creativecommons.org/licenses/LGPL/2.1/
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

int NUM_PARTICLES = 20;

VerletPhysics2D physics;
VerletParticle2D head,tail;
ParticleString2D pString;

boolean isTailLocked;

void setup() {
  size(1500,800);
  smooth();
  physics = new VerletPhysics2D();
  Vec2D headPos = new Vec2D(width / 10, height / 6);
  Vec2D tailPos = new Vec2D(width / 10, 5 * height / 6);
  Vec2D stepVec = new Vec2D(0,1).normalizeTo(headPos.distanceTo(tailPos) / NUM_PARTICLES);
  pString = new ParticleString2D(physics, headPos, stepVec, NUM_PARTICLES, 1, 0.00001);
  head = pString.getHead();
  tail = pString.getTail();
  head.lock();
  tail.lock();
  background(0);
  noStroke();
}

void draw() {
  physics.update();
  float speed = 0.2;
  Vec2D headVelocity = new Vec2D(speed * 5, speed * 1);
  Vec2D tailVelocity = new Vec2D(speed * 6, speed * - 1);
  if (head.x < 700) {
    head.set(head.x + headVelocity.x, head.y + headVelocity.y);
  }
  if (tail.x < 700) {
    tail.set(tail.x + tailVelocity.x, tail.y + tailVelocity.y);
  }

  // DEBUG
  // background(0);
  // stroke(255,100);
  // noFill();
  // beginShape();
  // for(Iterator i=physics.particles.iterator(); i.hasNext();) {
  //   VerletParticle2D p=(VerletParticle2D)i.next();
  //   vertex(p.x,p.y);
  // }
  // endShape();
  // DEBUG

  Iterator particleIterator = pString.particles.iterator();
  for(; particleIterator.hasNext();) {
    VerletParticle2D p1 = (VerletParticle2D)particleIterator.next();
    if (particleIterator.hasNext()) {
      VerletParticle2D p2 = (VerletParticle2D)particleIterator.next();
      Vec2D p = p1.interpolateTo(p2, 0.5);
      float diam = p1.distanceTo(p2);
      float k = .01;
      float omega = 1;
      // float alph = (1 + cos(k * diam - omega)) * 50;
      float alph = 100.0;
      float r = abs(255 * cos(k * diam - 1));
      float g = abs(255 * cos(k * diam - 2));
      float b = abs(255 * cos(k * diam - 3));
      // float alph = 100.0;
      fill(r,g,b,alph);
      ellipse(p.x,p.y,2*diam,2*diam);
    }
  }
}

// void mousePressed() {
//   isTailLocked = !isTailLocked;
//   if (isTailLocked) {
//     tail.lock();
//   }
//   else {
//     tail.unlock();
//   }
// }
