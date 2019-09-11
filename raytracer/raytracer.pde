/*
  Ray Tracer
  ----------
  This program is able to render extremely simple 3D environments using ray tracing.
  
  Controls:
    WASD - Rotate scene
    QE - move light sources up and down relative to the camera
    OP - change field of view
  
  written by Adrian Margel, Winter late 2018
*/


class Ray{
  //the pixel location the ray was cast from
  int dispX;
  int dispY;
  //the 3d position of the ray
  Vector pos;
  //the direction the ray is headed in
  Vector dir;
  
  //the render distance for the ray
  int drawDist=40;
  //how close the ray must be to an object to consider it a "hit"
  float minDist=0.1;
  
  Ray(int dx,int dy,float FOV,int wide,int high){
    dispX=dx;
    dispY=dy;
    
    //calculate the ray's direction based on the field of view.
    float tx=dx-wide/2;
    float ty=dy-high/2;
    float tz=wide/(2*tan(FOV));
    dir=new Vector(tx,ty,tz);
    dir.normalise();
  }
  
  //cast ray
  void cast(Vector p,float scale,ArrayList<Shape> ss,ArrayList<Light> ls){
    
    //starting position for the ray
    pos=new Vector(p);
    //number of steps taken
    int step=0;
    float totalDist=0;
    
    //continue stepping ray until it hits something or goes outside of the render distance
    do{
      //step the ray and store the distance it stepped
      float tempDist=step(ss);
      //add the distance stepped to the total distance traveled by the ray
      totalDist+=tempDist;
      //increase the number of steps that have been taken
      step++;
      //if the ray has hit an object
      if(tempDist<minDist){
        //calculate the lighting from hitting the shape
        //find location that was hit
        Vector cp=getSurface(ss);
        
        //calculate the lighting from each light source
        float bright=0;
        for(Light l:ls){
          bright+=l.getLight(pos,cp);
        }
        //display the ray to screen
        fill(bright*255);
        rect(dispX,dispY,scale,scale);
        return;
      }
    }while(totalDist<drawDist);
    //if the ray has gone out of the render distance display a defualt background color
    fill(50);
    rect(dispX,dispY,scale,scale);
  }
  
  //find the slope of the surface of the nearest shape
  Vector getSurface(ArrayList<Shape> ss){
    float min=-1;
    Shape tempS=null;
    for(Shape s: ss){
      float temp=s.getDist(pos);
      if(min==-1||temp<min){
        min=temp;
        tempS=s;
      }
    }
    return tempS.getSurface(pos);
  }
  
  //step the ray and return the distance stepped
  float step(ArrayList<Shape> ss){
    float min=-1;
    
    //find the minimum distance to the ray
    for(Shape s: ss){
      float temp=s.getDist(pos);
      if(min==-1||temp<min)
        min=temp;
    }
    
    //if a shape was found move the ray
    if(min!=-1){
      Vector stepV=new Vector(dir);
      stepV.scaleVec(min);
      pos.addVec(stepV);
    }
    return min;
  }
}

//a sphere
class Shape{
  //radius of the sphere
  float rad;
  //the position of the shape
  Vector pos;
  
  Shape(Vector p,float r){
    pos=new Vector(p);
    rad=r;
  }
  
  //find the minimum distance from a point to the shape
  float getDist(Vector p){
    Vector temp=new Vector(p);
    temp.subVec(pos);
    return temp.getMagnitude()-rad;
  }
  
  //rotate the shape's z y position
  void rot1(Vector pivit,float rot){
    pos.subVec(pivit);
    float ta1=atan2(pos.z,pos.y);
    float tm=sqrt(pos.z*pos.z+pos.y*pos.y);
    ta1+=rot;
    pos.z=sin(ta1)*tm;
    pos.y=cos(ta1)*tm;
    pos.addVec(pivit);
  }
  
  //rotate the shape's z x position
  void rot2(Vector pivit,float rot){
    pos.subVec(pivit);
    float ta2=atan2(pos.z,pos.x);
    float tm=sqrt(pos.z*pos.z+pos.x*pos.x);
    ta2+=rot;
    pos.z=sin(ta2)*tm;
    pos.x=cos(ta2)*tm;
    pos.addVec(pivit);
  }
  
  //find the slope of the surface from a certain position
  Vector getSurface(Vector p){
    Vector temp=new Vector(p);
    temp.subVec(pos);
    temp.normalise();
    return temp;
  }
}

//a lightsource
class Light{
  //how birhgt the light is
  float brightness;
  //the position of the light
  Vector pos;
  
  Light(Vector p,float b){
    pos=new Vector(p);
    brightness=b;
  }
  
  //calculate the light's brightness based on distance
  float getLightD(Vector p){
    Vector temp=new Vector(pos);
    temp.subVec(p);
    float mag=temp.getMagnitude();
    return brightness/(mag*mag);
  }
  //calculate the light's brightness based on angle / slope of a surface
  float getLightA(Vector p,Vector cp){
    Vector temp=new Vector(pos);
    temp.subVec(p);
    temp.normalise();
    return VectorCalc.dotProduct(cp,temp);
  }
  //calculate the light's brightness
  //input position of the surface and the slope of the surface (cp)
  float getLight(Vector p,Vector cp){
    return  getLightA(p,cp)* getLightD(p);
  }
  
  //rotate the light source's z y positon
  void rot1(Vector pivit,float rot){
    pos.subVec(pivit);
    float ta1=atan2(pos.z,pos.y);
    float tm=sqrt(pos.z*pos.z+pos.y*pos.y);
    ta1+=rot;
    pos.z=sin(ta1)*tm;
    pos.y=cos(ta1)*tm;
    pos.addVec(pivit);
  }
  
  //rotate the light source's z x positon
  void rot2(Vector pivit,float rot){
    pos.subVec(pivit);
    float ta2=atan2(pos.z,pos.x);
    float tm=sqrt(pos.z*pos.z+pos.x*pos.x);
    ta2+=rot;
    pos.z=sin(ta2)*tm;
    pos.x=cos(ta2)*tm;
    pos.addVec(pivit);
  }
}

//the shapes to be rendered in the environment
ArrayList<Shape> envire;
//the light sources
ArrayList<Light> lights;

//the rays to be casted
Ray[][] rays;
//the camera position
Vector cPos=new Vector(0,0,0);

//how many of the rays are sampled (resolution)
int sample=8;
//counts number of frames rendered
int timer=0;
//the field of view
float FOVdiv=4;

void setup(){
  //setup size of screen
  size(1200,800);
  //setup number rays
  rays=new Ray[1200][800];
  initRays();
  
  //add shapes
  envire=new ArrayList<Shape>();
  envire.add(new Shape(new Vector(0,0,10),1));
  envire.add(new Shape(new Vector(5,0,10),1));
  envire.add(new Shape(new Vector(10,0,10),1));
  envire.add(new Shape(new Vector(-5,0,10),2));
  envire.add(new Shape(new Vector(-10,0,10),1));
  envire.add(new Shape(new Vector(10,0.8,10),1));
  
  //add lights
  lights=new ArrayList<Light>();
  lights.add(new Light(new Vector(-2,0,10),1));
  lights.add(new Light(new Vector(5,0,5),15));
  
  //turn off anti-aliasing stroke to speed up display
  noSmooth();
  noStroke();
}
void draw(){
  
  //increase resolution overtime
  timer++;
  if(sample>0&&timer%10==0){
    sample/=2;
  }
  
  //cast rays
  if(sample>0){
    for(int x=0;x<rays.length;x+=sample){
      for(int y=0;y<rays[0].length;y+=sample){
        rays[x][y].cast(cPos,sample,envire,lights);
      }
    }
  }
}

//move the scene based on user input
void keyPressed(){
  
  //rotate scene
  
  cPos.addVec(new Vector(0,0,10));
  if(key=='w'||key=='W'){
    for(Shape s:envire){
      s.rot1(cPos,0.1);
    }
    for(Light l:lights){
      l.rot1(cPos,0.1);
    }
  }
  if(key=='s'||key=='S'){
    for(Shape s:envire){
      s.rot1(cPos,-0.1);
    }
    for(Light l:lights){
      l.rot1(cPos,-0.1);
    }
  }
  if(key=='a'||key=='A'){
    for(Shape s:envire){
      s.rot2(cPos,0.1);
    }
    for(Light l:lights){
      l.rot2(cPos,0.1);
    }
  }
  if(key=='d'||key=='D'){
    for(Shape s:envire){
      s.rot2(cPos,-0.1);
    }
    for(Light l:lights){
      l.rot2(cPos,-0.1);
    }
  }
  cPos.subVec(new Vector(0,0,10));
  
  //move light sources
  if(key=='q'||key=='Q'){
    for(Light l:lights){
      l.pos.y++;
    }
  }
  if(key=='e'||key=='E'){
    for(Light l:lights){
      l.pos.y--;
    }
  }
  
  //change field of view
  if(key=='p'||key=='P'){
    FOVdiv+=0.1;
    initRays();
  }
  if(key=='o'||key=='O'){
    FOVdiv-=0.1;
    initRays();
  }
  
  //set low resolution to quickly render the new scene
  sample=8;
}

//setup rays to render
void initRays(){
  for(int x=0;x<rays.length;x++){
    for(int y=0;y<rays[0].length;y++){
      rays[x][y]=new Ray(x,y,PI/max(FOVdiv,2.1),rays.length,rays[0].length);
    }
  }
}
