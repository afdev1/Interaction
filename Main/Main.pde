import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;

import remixlab.bias.*;
import remixlab.bias.event.*;
import remixlab.dandelion.constraint.*;
import remixlab.dandelion.core.*;
import remixlab.dandelion.geom.*;
import remixlab.fpstiming.*;
import remixlab.proscene.*;
import remixlab.util.*;

PShape avion;

Scene scene;
InteractiveFrame avionFrame, camaraFrame;

ControlIO control;
ControlDevice microsoft, genius;

ControlButton mGat, mB2, mB3, mB4, mB5, mB6, mB7, mB8, gGat, gRojo, gBC, gBD;
ControlSlider mXx, mYy, mSlider, gXx, gYy, gSlider;

////////////////////////////////////////////////
static int SN_ID;
HIDAgent hidAgent;


public class HIDAgent extends Agent {
  float [] sens = {10, 10, 10, 6, 4, 10};
  
  public HIDAgent(Scene scn) {
    super(scn.inputHandler());
    SN_ID = MotionShortcut.registerID(6, "SN_SENSOR");
    addGrabber(avionFrame);//scene.eyeFrame());
    setDefaultGrabber(avionFrame);//scene.eyeFrame());
  }
  
  @Override
  public float[] sensitivities(MotionEvent event) {
    if (event instanceof DOF6Event)
      return sens;
    else
      return super.sensitivities(event);
  }
  
  @Override
  public DOF6Event feed() {
    float accel = (-mSlider.getValue()+2);
    return new DOF6Event(
    abs(gXx.getValue()+0.2549)>0.23?(gXx.getValue()+0.2549)*accel:0, 
    abs(gYy.getValue()+0.19215)>0.122?(gYy.getValue()+0.19215)*accel:0, 
    -mYy.getValue()*accel, 
    abs(gYy.getValue()+0.19215)>0.122?(gYy.getValue()+0.19215):0, 
    mXx.getValue(), 
    abs(gXx.getValue()+0.2549)>0.23?(gXx.getValue()+0.2549):0, 
    
    BogusEvent.NO_MODIFIER_MASK, SN_ID);
  }
}

void setup(){
  size(800,800,P3D);
  loadControls();
  texmap = loadImage("world32k.jpg"); 
  initializeSphere(sDetail);
  avion = loadShape("plane.obj");
  scene = new Scene(this);
  
  rect(0, 0, 1000, 1000);
  
  scene.setRadius(1000);//1000);
  //scene.setGridVisualHint(false);
  //scene.setAxesVisualHint(false);  
  scene.showAll();
  
  hidAgent = new HIDAgent(scene);
  
  avionFrame = new InteractiveFrame(scene);
  avionFrame.setShape(avion);
  avionFrame.translate(new Vec(275, 180, 0));
  avionFrame.rotate(new Quat(PI,0,0));
  avionFrame.scale(0.3);
  
  camaraFrame = new InteractiveFrame(scene, avionFrame);
  //fill(255);
  //camaraFrame.setShape(createShape(SPHERE,50));
  camaraFrame.translate(new Vec(0, 200, -600));
  camaraFrame.rotate(new Quat(PI,PI,PI));
  //camaraFrame.scale(0.3);
  
  // we bound some frame DOF6 actions to the gesture on both frames
  avionFrame.setMotionBinding(SN_ID, "translateRotateXYZ");
  scene.eyeFrame().setMotionBinding(SN_ID, "translateRotateXYZ");
  
  // and the custom behavior to the right mouse button
  avionFrame.setMotionBinding(RIGHT, "customBehavior");
  camaraFrame.setMotionBinding(LEFT, "rotate");
  
  
  scene.inputHandler().shiftDefaultGrabber(scene.eyeFrame(), avionFrame);
  smooth();
}

void draw(){
  background(255);
  renderGlobe();
  //scene.display();
  scene.drawFrames();
  
  
  //scene.eyeFrame().setPosition(camaraFrame.position());
  scene.camera().setPosition(camaraFrame.position());
  scene.camera().setOrientation(avionFrame.orientation().inverse());
  scene.camera().lookAt(avionFrame.position());

  
  //scene.eyeFrame().orientation().lookAt(avionFrame.position());
  
  //scene.eyeFrame().rotate(new Quat(PI, 0, 0));
  
  //println(-mSlider.getValue()+2);
  //shape(avion, 0,0,1,1);
  //println(mXx.getValue() + " " + mYy.getValue() + "," + gXx.getValue() + " " + gYy.getValue() );
  //println(scene.eyeFrame().position());
  //scene.eyeFrame().setPosition(mSlider.getValue()*300,300,gSlider.getValue()*300);
  //scene.eyeFrame().setRotation(mXx.getValue(),mYy.getValue(),gXx.getValue(),gYy.getValue());
}

void loadControls(){
 control = ControlIO.getInstance(this);
  microsoft = control.getDevice("Microsoft SideWinder Joystick");
  microsoft = control.getMatchedDevice("sidewinder");
  mGat = microsoft.getButton("Gatillo");
  mB2 = microsoft.getButton("B2");
  mB3 = microsoft.getButton("B3");
  mB4 = microsoft.getButton("B4");
  mB5 = microsoft.getButton("B5");
  mB6 = microsoft.getButton("B6");
  mB7 = microsoft.getButton("B7");
  mB8 = microsoft.getButton("B8");
  mXx = microsoft.getSlider("Xx");
  mYy = microsoft.getSlider("Yy");
  mSlider = microsoft.getSlider("Slider");
  
  genius = control.getDevice("Padix Co. Ltd. USB, 3-axis, 4-button joystick");
  genius = control.getMatchedDevice("genius");
  gGat = genius.getButton("Gatillo");
  gRojo = genius.getButton("Rojo");
  gBC = genius.getButton("BC");
  gBD = genius.getButton("BD");
  gXx = genius.getSlider("Xx");
  gYy = genius.getSlider("Yy");
  gSlider = genius.getSlider("Slider");
}


/////////////////////////////

void customBehavior(InteractiveFrame frame, MotionEvent event) {
  frame.screenRotate(event);
}

PImage bg;
PImage texmap;

int sDetail = 35;  // Sphere detail setting
float rotationX = 0;
float rotationY = 0;
float velocityX = 0;
float velocityY = 0;
float globeRadius = 400;
float pushBack = 0;

float[] cx, cz, sphereX, sphereY, sphereZ;
float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION = 0.5;
int SINCOS_LENGTH = int(360.0 / SINCOS_PRECISION);

void renderGlobe() {  
  //lights();
  fill(200);
  noStroke();
  textureMode(IMAGE);  
  texturedSphere(globeRadius, texmap);
}

void keyPressed() {
  if (key == 'y')
      scene.flip();
  //Shift the default grabber for all agents: mouseAgent, keyboardAgent and the hidAgent
  if ( key == 'i')
    scene.inputHandler().shiftDefaultGrabber(scene.eyeFrame(), avionFrame);
  if(key == ' ')
    if( scene.eyeFrame().isActionBound("hinge") ) {
      scene.eyeFrame().setMotionBinding(SN_ID, "translateRotateXYZ");
      scene.eye().lookAt(scene.center());
      scene.showAll();
    }
    else {
      scene.eyeFrame().setMotionBinding(SN_ID, "hinge");
      Vec t = new Vec(0,0,0.7*globeRadius);
      float a = TWO_PI - 2; 
      scene.camera().setPosition(t);
      //For HINGE to work flawlessly we need to line up the eye up vector along the anchor and
      //the camera position:
      scene.camera().setUpVector(Vec.subtract(scene.camera().position(), scene.anchor()));
      //The rest is just to make the scene appear in front of us. We could have just used
      //the space navigator itself to make that happen too.
      scene.camera().frame().rotate(new Quat(a, 0, 0));
    }
}

void initializeSphere(int res) {
  sinLUT = new float[SINCOS_LENGTH];
  cosLUT = new float[SINCOS_LENGTH];

  for (int i = 0; i < SINCOS_LENGTH; i++) {
    sinLUT[i] = (float) Math.sin(i * DEG_TO_RAD * SINCOS_PRECISION);
    cosLUT[i] = (float) Math.cos(i * DEG_TO_RAD * SINCOS_PRECISION);
  }

  float delta = (float)SINCOS_LENGTH/res;
  float[] cx = new float[res];
  float[] cz = new float[res];

  // Calc unit circle in XZ plane
  for (int i = 0; i < res; i++) {
    cx[i] = -cosLUT[(int) (i*delta) % SINCOS_LENGTH];
    cz[i] = sinLUT[(int) (i*delta) % SINCOS_LENGTH];
  }

  // Computing vertexlist vertexlist starts at south pole
  int vertCount = res * (res-1) + 2;
  int currVert = 0;

  // Re-init arrays to store vertices
  sphereX = new float[vertCount];
  sphereY = new float[vertCount];
  sphereZ = new float[vertCount];
  float angle_step = (SINCOS_LENGTH*0.5f)/res;
  float angle = angle_step;

  // Step along Y axis
  for (int i = 1; i < res; i++) {
    float curradius = sinLUT[(int) angle % SINCOS_LENGTH];
    float currY = -cosLUT[(int) angle % SINCOS_LENGTH];
    for (int j = 0; j < res; j++) {
      sphereX[currVert] = cx[j] * curradius;
      sphereY[currVert] = currY;
      sphereZ[currVert++] = cz[j] * curradius;
    }
    angle += angle_step;
  }
  sDetail = res;
}

// Generic routine to draw textured sphere
void texturedSphere(float r, PImage t) {
  int v1, v11, v2;
  r = (r + 240 ) * 0.33;
  beginShape(TRIANGLE_STRIP);
  texture(t);
  float iu=(float)(t.width-1)/(sDetail);
  float iv=(float)(t.height-1)/(sDetail);
  float u=0, v=iv;
  for (int i = 0; i < sDetail; i++) {
    vertex(0, -r, 0, u, 0);

    u+=iu;
  }
  vertex(0, -r, 0, u, 0);
  vertex(sphereX[0]*r, sphereY[0]*r, sphereZ[0]*r, u, v);
  endShape();   

  // Middle rings
  int voff = 0;
  for (int i = 2; i < sDetail; i++) {
    v1=v11=voff;
    voff += sDetail;
    v2=voff;
    u=0;
    beginShape(TRIANGLE_STRIP);
    texture(t);
    for (int j = 0; j < sDetail; j++) {
      vertex(sphereX[v1]*r, sphereY[v1]*r, sphereZ[v1++]*r, u, v);
      vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2++]*r, u, v+iv);
      u+=iu;
    }

    // Close each ring
    v1=v11;
    v2=voff;
    vertex(sphereX[v1]*r, sphereY[v1]*r, sphereZ[v1]*r, u, v);
    vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2]*r, u, v+iv);
    endShape();
    v+=iv;
  }
  u=0;

  // Add the northern cap
  beginShape(TRIANGLE_STRIP);
  texture(t);
  for (int i = 0; i < sDetail; i++) {
    v2 = voff + i;
    vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2]*r, u, v);
    vertex(0, r, 0, u, v+iv);    
    u+=iu;
  }
  vertex(sphereX[voff]*r, sphereY[voff]*r, sphereZ[voff]*r, u, v);
  endShape();
}