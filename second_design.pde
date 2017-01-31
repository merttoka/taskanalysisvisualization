import peasy.*; //<>//

// Akzidenz-Grotesk BQ Condensed A Medium
PFont titleFont;
// FagoCoTf Regular
PFont smallFont;

// colors
color c_mainwhite = color(235);
color c_mainyellow = color(229, 222, 27);
color c_mainback = color(255, 10);
color c_mainslice = color(57, 226, 112);
color c_maintimer = color(198, 81, 81);
color c_mainconflict = color(198, 81, 81);
color[] c_legend = {color(113, 99, 174), 
                    color(30, 148, 205), 
                    color(0, 178, 117), 
                    color(255, 211, 51), 
                    color(255, 109, 0), 
                    color(191, 18, 28)};

PGraphics canvas;

PeasyCam cam;
Selection_in_P3D_OPENGL_A3D select;
ArrayList<Task> tasks;
int selectedTask  = -1;
int selectedSlice = -1;

float globalMinTime = 999999;
float globalMaxTime = 0;
float globalMaxRadius = 0;
float timer = 0;
boolean animationStarted = false;
boolean isCheckConflicts = false;
boolean isSpatiallyPolar = false;
Resource[] conflict;

float maxRadius = 50; // max radius of polar coordiantes of a slice
float timeScale = 20; // x-axis exaggeration

// Default peasycam handlers
PeasyDragHandler defaultLeftClickHandler;
PeasyDragHandler defaultMiddleClickHandler;
PeasyDragHandler defaultRightClickHandler;
PeasyWheelHandler defaultZoomHandler;

void setup() {
  fullScreen(P3D);

  smooth(8);
  
  titleFont = createFont("AkzidenzGrotesk-MediumCondAlt.otf", 60);
  smallFont = createFont("FagoCoTf.otf", 20);
  textFont(titleFont);

  canvas = createGraphics(200, 200);
  canvas.beginDraw();
  canvas.smooth();
  canvas.clear();
  canvas.endDraw();

  cam = new PeasyCam(this, width/8, height/8, 0, 750);
  cam.setMinimumDistance(1);
  cam.setMaximumDistance(5000);
  cam.setResetOnDoubleClick(false);

  defaultZoomHandler = cam.getZoomWheelHandler();
  defaultLeftClickHandler = cam.getRotateDragHandler();
  defaultMiddleClickHandler = cam.getPanDragHandler(); 
  defaultRightClickHandler = cam.getZoomDragHandler();

  select = new Selection_in_P3D_OPENGL_A3D();

  loadData("tasks.csv");
}

void draw() {
  background(20);
  select.captureViewMatrix((PGraphics3D)g);

  resetConflict();

  lights(); //<>//

  for (int i = 0; i < tasks.size(); i++) { 
    pushMatrix();
    PVector translate = getTranslate(i);
    translate(translate.x, translate.y, translate.z);
    drawAllConflictingSlices(i);
    drawTask(i, i==selectedTask);
    popMatrix();
  }
  
  drawCircularTimer();
  
  drawConflictsonHUD();
  drawHUD();
}

//  ----------------- BEGIN CONFLICT FUNCTIONS -----------------
void resetConflict() {
  // Current cumulative resource usage
  conflict = new Resource[6];
  conflict[0] = new Resource("People", 0);
  conflict[1] = new Resource("Hardware", 0);
  conflict[2] = new Resource("Tools", 0);
  conflict[3] = new Resource("Consumables", 0);
  conflict[4] = new Resource("Software", 0);
  conflict[5] = new Resource("Attire", 0);
}

int getConflictIndex(String s) {
  switch(s) {
  case "People":      
    return 0; 
  case "Hardware":    
    return 1; 
  case "Tools":       
    return 2; 
  case "Consumables": 
    return 3; 
  case "Software":    
    return 4; 
  case "Attire":      
    return 5; 
  default: 
    return -1;
  }
}
void checkConflict(String resourceName, float value) {
  int index = getConflictIndex(resourceName);

  if (index == -1)
    return;

  conflict[index].name = resourceName;
  conflict[index].usage += value;
}
//  ----------------- END CONFLICT FUNCTIONS -----------------

void drawTask(int index, boolean selected) {
  Task t = tasks.get(index);
  int timeframes = t.slices.size();
  int resources = t.slices.get(0).resources.size();

  // Timer intersection
  for (int i = 0; i < timeframes; ++i) {
    ArrayList<Resource> r = t.slices.get(i).resources;
    ArrayList<Resource> r2= t.slices.get((i+1)%timeframes).resources;

    // Timer Intersection
    if (timer > t.slices.get(i).timestamp * timeScale &&
      timer < t.slices.get((i+1)%timeframes).timestamp * timeScale)
    {
      PShape s = createShape();
      float x1 = t.slices.get(i).timestamp * timeScale;
      float x2 = t.slices.get((i+1)%timeframes).timestamp * timeScale;

      s.beginShape();
      s.noFill();
      s.strokeWeight(4);
      s.stroke(c_maintimer, 200);
      for (int j = 0; j <= r.size(); ++j) {
        float val1 = r.get(j % resources).usage;
        float val2 = r2.get(j % resources).usage;
        float interpolated = lerp(val1, val2, map(timer, x1, x2, 0, 1));
        if (j != r.size())
          checkConflict(r.get(j % resources).name, interpolated);

        s.vertex(timer, 
          cos(TWO_PI/resources*j)*maxRadius * interpolated * 1.1, 
          sin(TWO_PI/resources*j)*maxRadius * interpolated * 1.1);
      }
      s.endShape();
      shape(s);
    }
  }

  // Draw Timeframe slices
  for (int i = 0; i < timeframes; ++i) {
    ArrayList<Resource> r = t.slices.get(i).resources;

    if (i == selectedSlice && index == selectedTask) {
      stroke(c_mainslice, 100);
      fill(c_mainslice);
    } else if (!selected) {
      stroke(200, 30);
      fill(200, 30);
    } else {
      stroke(200, 200);
      fill(200);
    }
    beginShape();
    for (int j = 0; j <= r.size(); ++j) {
      vertex(t.slices.get(i).timestamp * timeScale, 
        cos(TWO_PI/resources*j)*maxRadius * r.get(j % resources).usage, 
        sin(TWO_PI/resources*j)*maxRadius * r.get(j % resources).usage);
    }
    endShape();

    // Selected Slice
    if (i == selectedSlice && index == selectedTask) {
      // Offset piece for selected slice
      noFill();
      stroke(c_mainslice, 200);
      beginShape();
      for (int j = 0; j <= r.size(); ++j) {
        vertex(t.slices.get(i).timestamp * timeScale, 
          cos(TWO_PI/resources*j)*maxRadius * (r.get(j % resources).usage+0.15), 
          sin(TWO_PI/resources*j)*maxRadius * (r.get(j % resources).usage+0.15));
      }
      endShape();

      // names of the resources       
      for (int j = 0; j <= r.size(); ++j) {
        pushMatrix();
        translate(t.slices.get(i).timestamp * timeScale, 
          cos(TWO_PI/resources*j)*maxRadius * (r.get(j % resources).usage+0.35), 
          sin(TWO_PI/resources*j)*maxRadius * (r.get(j % resources).usage+0.35));
        rotateY(PI/2);
        textAlign(CENTER);
        textSize(6);
        fill(255);
        text(r.get(j % resources).name, 0, 0, 0);
        textSize(12);
        textAlign(LEFT);
        popMatrix();
      }
    }
  }

  // Draw Outer Shell
  if (selectedTask == -1) {         
    stroke(255);
    fill(200, 200);
  } else if (!selected) {
    stroke(200, 30);
    fill(200, 30);
  } else {
    stroke(255);
    fill(200, 200);
  }

  for (int i = 0; i < timeframes-1; ++i)
  {
    ArrayList<Resource> r = t.slices.get(i).resources;
    ArrayList<Resource> r2 = t.slices.get(i+1).resources;

    beginShape(QUAD_STRIP);
    for (int j = 0; j <= r.size(); ++j) {
      vertex(t.slices.get(i).timestamp * timeScale, 
        cos(TWO_PI/resources*j)*maxRadius * r.get(j % resources).usage, 
        sin(TWO_PI/resources*j)*maxRadius * r.get(j % resources).usage);
      vertex(t.slices.get(i+1).timestamp * timeScale, 
        cos(TWO_PI/resources*j)*maxRadius * r2.get(j % resources).usage, 
        sin(TWO_PI/resources*j)*maxRadius * r2.get(j % resources).usage);
    }
    endShape(QUAD_STRIP);
  }

  // Bounding Box Draw and calculate
  pushMatrix();
  float w = t.getMaxTime() * timeScale - t.getMinTime() * timeScale;
  translate(t.slices.get(0).timestamp * timeScale + w/2, 0, 0);
  //noFill();
  //stroke(0,0,255);
  //box(w, 1.5* maxRadius, 1.5*maxRadius);

  PVector center = new PVector(modelX(0, 0, 0), modelY(0, 0, 0), modelZ(0, 0, 0));
  PVector min = new PVector(center.x-w/2, center.y-0.75*maxRadius, center.z-0.75*maxRadius);
  PVector max = new PVector(center.x+w/2, center.y+0.75*maxRadius, center.z+0.75*maxRadius);
  t.bb = new BBox(min, max, center);
  popMatrix(); 

  // Task Title
  textSize(18);
  textAlign(LEFT);
  text(t.getTitle(), t.slices.get(0).timestamp * timeScale, maxRadius, 0);

  // Task Axis
  color c = color(c_mainyellow);
  stroke(c, 150);
  line((globalMinTime-1) *timeScale, 0, 0, 
    t.getMinTime() * timeScale, 0, 0);
  hint(DISABLE_DEPTH_TEST);
  stroke(c, 100);
  line(t.getMinTime() * timeScale, 0, 0, 
    t.getMaxTime() * timeScale, 0, 0);
  hint(ENABLE_DEPTH_TEST);
  stroke(c, 150);
  line(t.getMaxTime() * timeScale, 0, 0, 
    (globalMaxTime+1) *timeScale, 0, 0);

}

//  ----------------- BEGIN CONFLICT FUNCTIONS -----------------
void drawAllConflictingSlices(int index){
  if (!isCheckConflicts)
    return;
    
  for(int i = 0; i < tasks.get(index).conflictingResources.size(); i++){
    shape(tasks.get(index).conflictingResources.get(i));
  }
}
void findConflictSlices() {
  for (float time = globalMinTime; time < globalMaxTime; time += .25) {
    resetConflict();
    for (int k = 0; k < tasks.size(); k++) {
      Task t = tasks.get(k);
      for (int i = 0; i < t.slices.size(); ++i) {
        TaskSlice s = t.slices.get(i);
        TaskSlice s2= t.slices.get((i+1)%t.slices.size());

        ArrayList<Resource> r = s.resources;
        ArrayList<Resource> r2= s2.resources;

        if (time > s.timestamp && time < s2.timestamp)
        {
          float x1 = s.timestamp;
          float x2 = s2.timestamp;

          int resources = r.size();
          for (int j = 0; j <= resources; ++j) {
            float val1 = r.get(j % resources).usage;
            float val2 = r2.get(j % resources).usage;
            float interpolated = lerp(val1, val2, map(time, x1, x2, 0, 1));
            if (j != r.size())
              checkConflict(r.get(j % resources).name, interpolated);
          }
        }
      }
    }
    boolean isDrawConflict = false;
    for (int j = 0; j < conflict.length; j++) {
      if (conflict[j].usage > 1) {
        isDrawConflict = true;
      }
    }
    if (isDrawConflict) {
      for (int k = 0; k < tasks.size(); k++) {
        
        Task t = tasks.get(k);
        for (int i = 0; i < t.slices.size(); ++i) {
          TaskSlice s = t.slices.get(i);
          TaskSlice s2= t.slices.get((i+1)%t.slices.size());

          ArrayList<Resource> r = s.resources;
          ArrayList<Resource> r2= s2.resources;

          if (time > s.timestamp && time <= s2.timestamp)
          {
            float x1 = s.timestamp;
            float x2 = s2.timestamp;
            
            PShape cut = createShape();  
            
            cut.beginShape();
            cut.noFill();
            cut.strokeWeight(3);
            float c_red = 0;
            float c_green = 0;
            float c_blue = 0;
            float c_totalWeight = 0;
            for(int ii = 0; ii < conflict.length; ii++){
              if(conflict[ii].usage > 1){
                c_totalWeight += conflict[ii].usage;
                c_red += red(c_legend[ii]);
                c_green += green(c_legend[ii]);
                c_blue += blue(c_legend[ii]);
              }
            }
            color c = color(c_red/c_totalWeight, c_green/c_totalWeight, c_blue/c_totalWeight);
            cut.stroke(c, 220);
            int resources = r.size();
            for (int j = 0; j <= resources; ++j) {
              float val1 = r.get(j % resources).usage;
              float val2 = r2.get(j % resources).usage;
              float interpolated = lerp(val1, val2, map(time, x1, x2, 0, 1));

              cut.vertex(time*timeScale, 
                cos(TWO_PI/resources*j)*maxRadius * interpolated * 1.1, 
                sin(TWO_PI/resources*j)*maxRadius * interpolated * 1.1);
            }
            cut.endShape();
        
            t.addConflictingResource(cut);
          }
        }
      }
    }
  }
}
//  ----------------- END CONFLICT FUNCTIONS -----------------

// Loads data over csv file
void loadData(String filename) {
  
  selectedTask  = -1;
  selectedSlice = -1;
  
  tasks = new ArrayList<Task>();

  Table table = loadTable(filename, "header");

  println("\n"+table.getRowCount() + " total rows in table"); 

  for (TableRow row : table.rows()) {   
    ArrayList<Resource> resArr = new ArrayList<Resource>();
    if (!Float.isNaN(row.getFloat("r_hardware")))
      resArr.add(new Resource("Hardware", row.getFloat("r_hardware")));
    if (!Float.isNaN(row.getFloat("r_software")))
      resArr.add(new Resource("Software", row.getFloat("r_software")));
    if (!Float.isNaN(row.getFloat("r_people")))
      resArr.add(new Resource("People", row.getFloat("r_people")));
    if (!Float.isNaN(row.getFloat("r_consumables")))
      resArr.add(new Resource("Consumables", row.getFloat("r_consumables")));
    if (!Float.isNaN(row.getFloat("r_attire")))
      resArr.add(new Resource("Attire", row.getFloat("r_attire")));
    if (!Float.isNaN(row.getFloat("r_tools")))
      resArr.add(new Resource("Tools", row.getFloat("r_tools")));

    // if already exists in the array
    int index;
    if ((index = isExist(row.getString("task_title"))) != -1) {
      tasks.get(index)
        .addSlice(row.getFloat("time_stamp"), 
        row.getFloat("risk"), 
        row.getFloat("difficulty"), 
        resArr);
    } else
    {
      Task t = new Task(row.getString("task_title"));
      t.addSlice(row.getFloat("time_stamp"), 
        row.getFloat("risk"), 
        row.getFloat("difficulty"), 
        resArr);
      tasks.add(t);
    }
  }

  globalMinTime=99999999;
  globalMaxTime=-50;
  for (int i = 0; i < tasks.size(); i++) {
    globalMinTime = min(globalMinTime, tasks.get(i).getMinTime());
    globalMaxTime = max(globalMaxTime, tasks.get(i).getMaxTime());
  }

  findConflictSlices();

  println("\nData loaded: "+ tasks.size() + " tasks.");
}
int isExist(String task_title) {
  for (int i=0; i < tasks.size(); i++) {
    if (task_title.equals(tasks.get(i).getTitle())) {
      return i;
    }
  }
  return -1;
}

// Draws timer circle
void drawCircularTimer() {
  colorMode(HSB, 360, 100, 100);
  color c_fill = color(0, 30, 30);
  color c_stroke = color(360, 0, 100);
  pushMatrix();
    rotateY(PI/2);
    if(isSpatiallyPolar){
      translate(0, 0, timer);
    }
    else{
      translate(0, 0, timer);
    }
    fill(c_fill, 50);
    stroke(c_stroke, 50);
    float radius = globalMaxRadius;
    ellipse(0, 0, 2*radius, 2*radius);
    stroke(c_stroke, 15);
    for(int i = 0; i < 8; i++){
      line(0, 0, cos(i*QUARTER_PI) * radius, sin(i*QUARTER_PI) * radius);
    }
    int num = 7;
    for(int i = 0; i < num; i++)
    {
      noFill();
      ellipse(0,0, 2*radius - (i*2*radius/num), 2*radius - (i*2*radius/num));
    }    
  popMatrix();
  colorMode(RGB, 255, 255, 255);
  
  if(isSpatiallyPolar){
    String[] names = {"Risk", "People", "Hardware", "Tools", "Difficulty", "Consumables", "Software", "Attire"};
    for(int i = 0; i < 8; i++){
       float angle = i*QUARTER_PI;
        pushMatrix();
        translate(timer+1, cos(angle) * radius, sin(angle) * radius);
        rotateY(PI/2);
        textAlign(CENTER);
        textSize(40);
        fill(255);
        text(names[i], 0,0,0);
        popMatrix();
    }
    globalMaxRadius = 0;
  }
}

// Draws the axis on origin
void drawAxis(float scaleX, float scaleY, float scaleZ) {
  stroke(255, 50);
  line(0, 0, 0, scaleX, 0, 0);
  line(0, 0, 0, 0, scaleY, 0);
  line(0, 0, 0, 0, 0, scaleZ);
}

// Finds correct polar coordinate position of the task
PVector getTranslate(int index)
{
  if(!isSpatiallyPolar){
    globalMaxRadius = (tasks.size()+1)*100/2;
    return new PVector(0, (index-tasks.size()/2)*100, 50);
  }
  
  PVector spatialPos = new PVector();
  
  Task t = tasks.get(index);
  int timeframes = t.slices.size();
  int resources = t.slices.get(0).resources.size();
  
  ArrayList<Resource> spatialRes = new ArrayList<Resource>();
  // If timer hasn't reached task
  if(timer/timeScale <= t.getMinTime()){
    TaskSlice s = t.slices.get(0);
    for(int i = 0; i < s.resources.size(); i++){
      spatialRes.add(s.resources.get(i));
    }
  }
  // If timer is on the task
  else if(timer/timeScale > t.getMinTime() && timer/timeScale < t.getMaxTime()){
    for(int i = 0; i < timeframes; ++i){
      ArrayList<Resource> r = t.slices.get(i).resources;
      ArrayList<Resource> r2= t.slices.get((i+1)%timeframes).resources;
      // Timer Intersection
      if(timer > t.slices.get(i).timestamp * timeScale &&
         timer <= t.slices.get((i+1)%timeframes).timestamp * timeScale)
      {
        float x1 = t.slices.get(i).timestamp * timeScale;
        float x2 = t.slices.get((i+1)%timeframes).timestamp * timeScale;
        for(int j = 0; j < r.size(); ++j){
          String name = r.get(j % resources).name;
          float val1 = r.get(j % resources).usage;
          float val2 = r2.get(j % resources).usage;
          float interpolated = lerp(val1, val2, map(timer, x1, x2, 0, 1));
          spatialRes.add(new Resource(name, interpolated));
        }
        break;
      }
    }
  }
  // If timer left task
  else{
    TaskSlice s = t.slices.get(t.slices.size()-1);
    for(int i = 0; i < s.resources.size(); i++){
      spatialRes.add(s.resources.get(i));
    }
  }
  for(int i = 0; i < spatialRes.size(); ++i){
    float angle = 0;
    switch(spatialRes.get(i).name){
      case "Risk":       angle = 0; break;
      case "People":     angle = QUARTER_PI; break;
      case "Hardware":   angle = HALF_PI; break;
      case "Tools":      angle = 3*QUARTER_PI; break;
      case "Difficulty": angle = PI; break;
      case "Consumables":angle = 5*QUARTER_PI; break;
      case "Software":   angle = 6*QUARTER_PI; break;
      case "Attire":     angle = 7*QUARTER_PI; break;
    }
    
    spatialPos.y += cos(angle) * 500 * spatialRes.get(i).usage;
    spatialPos.z += sin(angle) * 500 * spatialRes.get(i).usage;
  }
  
  globalMaxRadius = max(globalMaxRadius, sqrt(pow(spatialPos.y,2)+pow(spatialPos.z,2))*1.1);
  
  return spatialPos;
}