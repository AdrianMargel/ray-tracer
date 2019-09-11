public class Vector{
  float x;
  float y;
  float z;
  Vector(float tx,float ty,float tz){
    x=tx;
    y=ty;
    z=tz;
  }
  Vector(Vector v){
    x=v.x;
    y=v.y;
    z=v.z;
  }
  void scaleVec(float scale){
    x*=scale;
    y*=scale;
    z*=scale;
  }
  void normalise(){
    scaleVec(1/getMagnitude());
  }
  void subVec(Vector v){
    x-=v.x;
    y-=v.y;
    z-=v.z;
  }
  void addVec(Vector v){
    x+=v.x;
    y+=v.y;
    z+=v.z;
  }
  float getMagnitude(){
    return (float)Math.sqrt(x*x+y*y+z*z);
  }
}