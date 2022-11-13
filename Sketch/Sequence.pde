class Sequence {
  int repeat;
  int repeatCounter = 0;
  JSONArray scenes;
  int stepCounter = 0;

  Sequence(
    JSONArray scenes,
    int repeat
  ) {
    this.scenes = scenes;
    this.repeat = repeat;
    this.repeatCounter = 0;
    this.stepCounter = 0;
  }

  int len() {
    return this.scenes.size();
  }

  void next() {
    this.stepCounter++;
    if (this.stepCounter == this.len()) {
      this.stepCounter = 0;
      this.repeatCounter++;
    }
  }

  boolean finished() {
    return this.repeatCounter == this.repeat;
  }

  boolean isAtFirstStep() {
    return this.stepCounter == 0;
  }

  boolean isAtFirstRepeat() {
    return this.repeatCounter == 0;
  }

  String currentStep() {
    return this.scenes.getString(this.stepCounter);
  }
}