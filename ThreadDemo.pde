import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;


int NUM_PARTICLES = 10;
float STRENGTH = .002;
int headCurrentStage = 0;
int tailCurrentStage = 0;

int stage () {
  return min(headCurrentStage, tailCurrentStage);
}

float[] speeds = new float[] { 3, 6, 2 };

Vec2D[] headPositions = new Vec2D[] {
  new Vec2D(200, 300), // stage one start
  new Vec2D(1300, 150), // stage two start
  new Vec2D(900, 500), // stage three start
  new Vec2D(0, 900) // end
};

Vec2D[] tailPositions = new Vec2D[] {
  new Vec2D(200, 700), // stage one start
  new Vec2D(1400, 450), // stage two start
  new Vec2D(1250, 500), // stage three start
  new Vec2D(0, 900) // end
};

Stage[] createStages() {
  int numberOfStages = speeds.length;
  Stage[] stages = new Stage[numberOfStages];
  for (int i = 0; i < numberOfStages; i++) {
    stages[i] = new Stage(
      // Origins
      new Vec2D[] {
        headPositions[i],
        tailPositions[i]
      },
      // Targets
      new Vec2D[] {
        headPositions[i + 1],
        tailPositions[i + 1]
      },
      // Speeds
      new float[] {
        speeds[i],
        speeds[i]
      }
    );
  }
  return stages;
}

Stage[] stages = createStages();

ToxiColorString colorString;
VerletParticle2D head, tail;

void setup() {
  size(1600,900);
  smooth();
  physics = new VerletPhysics2D();

  Vec2D headStartPos = stages[0].headPosOrigin;
  Vec2D tailStartPos = stages[0].tailPosOrigin;

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
    if (stages.length - 1 != headCurrentStage) {
      // Fix error cripping
      head.set(stages[headCurrentStage].headPosOrigin);
    }
  }

  if (
    stages[currentStage].tailOvershoot(tail)
  ) {
    tailCurrentStage = min(stages.length - 1, currentStage + 1);
    if (stages.length - 1 != tailCurrentStage) {
      // Fix error cripping
      tail.set(stages[tailCurrentStage].tailPosOrigin);
    }
  }

  float omega = .8 * TWO_PI;
  // colorString.displayStraight(0.002, omega);
  colorString.displayOneInTwo(0.04, .1 * TWO_PI);
  colorString.display(0.02, omega);
  // background(0);
  // colorString.displaySkeleton();
  // stages[currentStage].displayDebug();

  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
