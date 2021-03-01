import toxi.physics2d.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;
import toxi.math.*;

import java.util.Iterator;

VerletPhysics2D physics;

class ToxiColorTrail {
  public Stage[] stages;
  private int headCurrentStage = 0;
  private int tailCurrentStage = 0;

  ToxiColorString colorString;
  VerletParticle2D head, tail;

  ToxiColorTrail(
    VerletPhysics2D physics,
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions,
    int numLinks,
    float mass,
    float strength
  ) {
    this.createStages(
      speeds,
      headPositions,
      tailPositions
    );
    this.createColorString(
      physics,
      headPositions[0],
      tailPositions[0],
      numLinks,
      mass,
      strength
    );
  }

  int getCurrentStage () {
    return min(this.headCurrentStage, this.tailCurrentStage);
  }

  private void createColorString (
    VerletPhysics2D physics,
    Vec2D headStartPos,
    Vec2D tailStartPos,
    int numLinks,
    float mass,
    float strength
  ) {
    this.colorString = new ToxiColorString(physics, headStartPos, tailStartPos, numLinks, mass, strength);
    this.head = colorString.head;
    this.tail = colorString.tail;
  }

  public void update () {
    int currentStage = this.getCurrentStage();

    Vec2D currentHeadVelocity = this.stages[currentStage].headVelocity;
    Vec2D currentTailVelocity = this.stages[currentStage].tailVelocity;

    if (this.headCurrentStage == currentStage) {
      this.head.set(this.head.x + currentHeadVelocity.x, this.head.y + currentHeadVelocity.y);
    }
    if (this.tailCurrentStage == currentStage) {
      this.tail.set(this.tail.x + currentTailVelocity.x, this.tail.y + currentTailVelocity.y);
    }

    if (
      this.stages[currentStage].headOvershoot(this.head)
    ) {
      this.headCurrentStage = min(this.stages.length - 1, currentStage + 1);
      if (this.stages.length - 1 != this.headCurrentStage) {
        // Fix error cripping
        this.head.set(this.stages[this.headCurrentStage].headPosOrigin);
      }
    }

    if (
      this.stages[currentStage].tailOvershoot(this.tail)
    ) {
      this.tailCurrentStage = min(this.stages.length - 1, currentStage + 1);
      if (this.stages.length - 1 != this.tailCurrentStage) {
        // Fix error cripping
        this.tail.set(this.stages[this.tailCurrentStage].tailPosOrigin);
      }
    }
  }

  private void createStages(
    float[] speeds,
    Vec2D[] headPositions,
    Vec2D[] tailPositions
  ) {
    if (headPositions.length != tailPositions.length) {
      throw new Error("must have as many head positions as tail positions");
    }
    if (speeds.length + 1 != headPositions.length) {
      throw new Error("Must have exactly one speed per section (3 positions -> 2 speeds, speed1 between point 1 and point 2 and speed 2 between point 2 and point 3)");
    }

    int numberOfStages = speeds.length;
    this.stages = new Stage[numberOfStages];
    for (int i = 0; i < numberOfStages; i++) {
      this.stages[i] = new Stage(
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
  }
}

int NUM_PARTICLES = 10;
float STRENGTH = .004;

float[] speeds = new float[] { 1, 2, .6 };

Vec2D[] headPositions = new Vec2D[] {
  new Vec2D(450, 250), // stage one start
  new Vec2D(700, 200), // stage two start
  new Vec2D(900, 400), // stage three start
  new Vec2D(1150, 400) // end
};

Vec2D[] tailPositions = new Vec2D[] {
  new Vec2D(450, 350), // stage one start
  new Vec2D(700, 350), // stage two start
  new Vec2D(750, 500), // stage three start
  new Vec2D(1150, 500) // end
};

ToxiColorTrail colorTrail;

void setup() {
  size(1600, 900);
  smooth();
  physics = new VerletPhysics2D();
  colorTrail = new ToxiColorTrail(
      physics,
      speeds,
      headPositions,
      tailPositions,
      NUM_PARTICLES - 1,
      1,
      STRENGTH
  );
  background(0);
  noStroke();
}

void draw() {
  physics.update();
  colorTrail.update();

  float omega = .8 * TWO_PI;
  colorTrail.colorString.display(0.02, omega);
  colorTrail.colorString.displayOneInTwo(0.02, omega);
  // colorTrail.colorString.displaySkeleton();
  // colorTrail.stages[colorTrail.getCurrentStage()].displayDebug();

  //  saveFrame("out/screen-####.tif");
}

void keyPressed() {
  if (key == ' ') {
    saveFrame();
  }
}
