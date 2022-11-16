class SequenceConfig {
  SequenceConfig() {}
  JSONArray scenes;
  int repeat;
}

class Sequence {
  int repeat;
  int repeatCounter = 0;
  JSONArray scenes;
  int sceneIndexCounter = 0;

  Sequence(SequenceConfig config) {
    this.scenes = config.scenes;
    this.repeat = config.repeat;
    this.repeatCounter = 0;
    this.sceneIndexCounter = 0;
  }

  int len() {
    return this.scenes.size();
  }

  void next() {
    this.sceneIndexCounter++;
    if (this.sceneIndexCounter == this.len()) {
      this.sceneIndexCounter = 0;
      this.repeatCounter++;
    }
  }

  boolean finished() {
    return this.repeatCounter == this.repeat;
  }

  boolean isAtFirstScene() {
    return this.sceneIndexCounter == 0;
  }

  boolean isAtFirstRepeat() {
    return this.repeatCounter == 0;
  }

  String currentScene() {
    return this.scenes.getString(this.sceneIndexCounter);
  }
}