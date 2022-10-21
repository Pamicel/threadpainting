float signedAngleBetweenVectors (Vec2D vector1, Vec2D vector2) {
  return atan2(vector2.y, vector2.x) - atan2(vector1.y, vector1.x);
}