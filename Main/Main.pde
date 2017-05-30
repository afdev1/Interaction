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
  float [] sens = {10, 10, 50, 5, 4, 5};
  
  public HIDAgent(Scene scn) {
    super(scn.inputHandler());
    SN_ID = MotionShortcut.registerID(6, "SN_SENSOR");
    addGrabber(avionFrame);
    setDefaultGrabber(avionFrame);
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
    abs(gXx.getValue()+0.2549)>0.23?(gXx.getValue()+0.2549):0, 
    (abs(gYy.getValue()+0.19215)>0.122?(gYy.getValue()+0.19215):0) + gSlider.getValue()*20, 
    -mYy.getValue()*accel, 
    (abs(gYy.getValue()+0.19215)>0.122?(gYy.getValue()+0.19215):0), 
    mXx.getValue(), 
    abs(gXx.getValue()+0.2549)>0.23?(gXx.getValue()+0.2549):0, 
    
    BogusEvent.NO_MODIFIER_MASK, SN_ID);
  }
}

PShape s;
void setup(){
  size(800,800,P3D);
  loadControls();
  avion = loadShape("plane.obj");
  scene = new Scene(this);
  
  rect(0, 0, 1000, 1000);
  
  scene.setRadius(2000);//1000);
  scene.setGridVisualHint(false);
  scene.setAxesVisualHint(false);  
  scene.showAll();
  
  s = loadShape("city.obj");
  
  hidAgent = new HIDAgent(scene);
  
  avionFrame = new InteractiveFrame(scene);
  avionFrame.setShape(avion);
  avionFrame.translate(new Vec(275, 500, 0));
  avionFrame.rotate(new Quat(PI,0,0));
  avionFrame.scale(0.1);
  
  camaraFrame = new InteractiveFrame(scene, avionFrame);
  camaraFrame.translate(new Vec(0, -200, -800));
  camaraFrame.rotate(new Quat(PI,PI,PI));
  
  avionFrame.setMotionBinding(SN_ID, "translateRotateXYZ");
  scene.eyeFrame().setMotionBinding(SN_ID, "translateRotateXYZ");
  
  avionFrame.setMotionBinding(RIGHT, "customBehavior");
  camaraFrame.setMotionBinding(LEFT, "rotate");
  
  
  scene.inputHandler().shiftDefaultGrabber(scene.eyeFrame(), avionFrame);
  smooth();
}

void draw(){
  background(255);
    
  directionalLight(255, 255, 255, 0.5, -1, 0);
  shape(s, -100, 0);
  scene.drawFrames();
  
  scene.camera().setPosition(camaraFrame.position());
  scene.camera().setOrientation(avionFrame.orientation());
  scene.camera().lookAt(avionFrame.position());
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
    
}