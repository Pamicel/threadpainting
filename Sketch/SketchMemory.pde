// class SketchMemory {
//   String configPath =  "config/config.json";

//   int seed;

//   TrailRenderer[] trailRenderers;

//   SketchMemory() {}

//   Sequence loadSequence() {
//     JSONObject config = loadJSONObject(this.configPath);
//     JSONArray steps = config.getJSONArray("steps");

//     String outputType = config.getString("output");
//     Output output = Output.DRAW;
//     if (outputType.equals("VIDEO")) {
//       output = Output.VIDEO;
//     }

//     int videoNumFrames = config.getInt("videoNumFrames");
//     int repeat = config.getInt("repeat");
//     return new Sequence(
//       steps,
//       repeat == 0 ? 1 : repeat,
//       output,
//       videoNumFrames
//     );
//     }

// }