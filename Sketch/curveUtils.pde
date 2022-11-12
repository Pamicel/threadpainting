Vec2D[] curveFromJSONArray(JSONArray rawCurve, float layerScale) {
  Vec2D[] curve = new Vec2D[rawCurve.size()];
  for (int i = 0; i < rawCurve.size(); i++) {
    JSONObject point = rawCurve.getJSONObject(i);
    float x = point.getFloat("x") / layerScale;
    float y = point.getFloat("y") / layerScale;
    curve[i] = new Vec2D(x, y);
  }
  return curve;
}

class ResampleConfig {
  ResampleConfig() {}
  boolean resample;
  boolean resampleRegular;
  int resampleLen;
}

Vec2D[] applyResampleToCurve(Vec2D[] curve, ResampleConfig resampleConfig) {
  int resampleLen = resampleConfig.resampleLen;
  boolean resample = resampleConfig.resample;
  boolean resampleRegular = resampleConfig.resampleRegular;

  if (resample && resampleLen != 0) {
    if (resampleRegular) {
      return regularResample(curve, resampleLen);
    }
    return resample(curve, resampleLen);
  }
  return curve;
}