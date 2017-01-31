void drawConflictsonHUD(){
  noLights();
  cam.beginHUD();
  
  try{
    // TITLE AND DAY COUNT
    textAlign(CENTER, CENTER);
    textSize(40);
    fill(c_mainwhite);
    text("Cumulative Resources", width-178 , height-230);
    noStroke();
    fill(c_mainback);
    ellipse(width-40, height-240, 90,90);
    textSize(50);
    fill(c_mainyellow);
    text(int(timer/timeScale), width-40, height-240);
    textSize(15);
    text("days", width-40, height-210);
    
    // LEGEND AND USAGE
    textFont(smallFont);
    for(int i = 0; i < conflict.length; i++){
      fill(c_legend[i]);
      rectMode(CENTER);
      rect(width-175 , height-195+i*26, 6, 20);
      rectMode(CORNER);
      
      fill(c_mainwhite);
      textAlign(RIGHT, CENTER);
      text(conflict[i].name, width-186 , height-195+i*26);
      
      if(conflict[i].usage >= 1)
        fill(c_mainconflict);
      else if(conflict[i].usage == 0)
        fill(c_mainwhite, 150);
      else
        fill(c_mainwhite);
      textAlign(LEFT, CENTER);
      text(nfc(conflict[i].usage, 2), width-165 , height-195+i*26);
    }
    textFont(titleFont);
  }catch(Exception e){
    e.printStackTrace();
  }
  cam.endHUD();
  lights();
}

// Draws HUD Elements
void drawHUD(){
  try{
    noLights();
    // Signature decay
    canvas.beginDraw();
    canvas.loadPixels();
    for(int i = 0; i < canvas.width*canvas.height; i++){
      canvas.pixels[i] = color(red(canvas.pixels[i]), alpha(canvas.pixels[i])*.99); 
    }
    canvas.updatePixels();
    canvas.endDraw();
    
    cam.beginHUD();
    
    // Actual drawing of the signature 
    image(canvas, 0, 0);
    
    // Timer bar display and update
    if(animationStarted){
      timer += 0.3;
    }
    
    // Slider background
    noStroke();
    fill(c_mainback);
    rect(10, height-40, width-20, 30);
    if(mouseY > height - 50){
      //slider object
      fill(c_mainyellow, 200);
      ellipse(constrain(mouseX, 17.5, width-17.5), 
              constrain(mouseY, height-32.5, height-17.5), 15, 15);
      cam.setLeftDragHandler(new PeasyDragHandler(){
         public void handleDrag(final double dx, final double dy){
           timer += dx;
           if(timer < 0) timer = 0;
         }
      });
    }
    else
      cam.setLeftDragHandler(defaultLeftClickHandler);
    
    if(selectedTask != -1 && selectedSlice != -1){
      TaskSlice s = tasks.get(selectedTask).slices.get(selectedSlice);
      
      // Signature painting
      canvas.beginDraw();
      canvas.pushMatrix();
      canvas.translate(canvas.width/2, canvas.height/2);
      canvas.rotate(PI/2);
      canvas.noFill();
      canvas.stroke(170, 170, 170, 100);
      canvas.beginShape();
      for(int j = 0; j <= s.resources.size(); ++j){
        canvas.vertex(cos(TWO_PI/s.resources.size()*j) * 
                         min(canvas.width/2-canvas.width/8, canvas.height/2-canvas.height/8) * 
                         (s.resources.get(j % s.resources.size()).usage+0.15),
                     sin(TWO_PI/s.resources.size()*j) * 
                         min(canvas.width/2-canvas.width/8, canvas.height/2-canvas.height/8) * 
                         (s.resources.get(j % s.resources.size()).usage+0.15));
      }
      canvas.endShape();
      canvas.popMatrix();
      canvas.endDraw();
      
      // TITLE
      textAlign(LEFT, CENTER);
      textSize(60);
      noStroke();
      fill(c_mainback);
      rect(0,50, textWidth(tasks.get(selectedTask).getTitle())+120, 100);
      fill(c_mainyellow);
      String firstPart = tasks.get(selectedTask).getTitle().substring(0,3);
      text(firstPart, 100, 100);
      fill(c_mainwhite);
      text(tasks.get(selectedTask).getTitle().substring(4), textWidth(firstPart)+100, 100);
      
      // RISK, DIFFICULTY, and RESOURCES
      float offset = textWidth(tasks.get(selectedTask).getTitle())+120+40;
      noFill();
      stroke(255, 100);
      ellipse(offset+45, 100, 90, 90);
      ellipse(offset+90+40+45, 100, 90, 90); 
      ellipse(offset+90+40+90+40+45, 100, 90, 90);
      textAlign(LEFT, BOTTOM);
      textSize(30);
      fill(c_mainwhite);
      text("risk", offset-2, 150);
      text("difficulty", offset-2+90+40, 150);
      text("resources", offset-2+90+40+90+40, 150);
      textAlign(CENTER, CENTER);
      textSize(48);
      fill(c_mainyellow);
      text(nfc(s.resources.get(s.resources.size()-2).usage, 2), offset+45, 100);
      text(nfc(s.resources.get(s.resources.size()-1).usage, 2), offset+90+40+45, 100);
      text(s.resources.size()-2, offset+90+40+90+40+45, 100);
      
      // The Graph
      image(constructGraph(400,200), 20, 210);
    }
    cam.endHUD();
    lights();
  }catch(Exception e){
    // File may be edited while last indexed slice selected
    println("Something went wrong.");
  }
}
boolean toggleGraphType = false;
PGraphics constructGraph(int w, int h){
  PGraphics pg = createGraphics(w, h);
  pg.beginDraw();
  pg.smooth();
  pg.translate(5,0);
  pg.clear();
  
  if(selectedTask == -1){
    pg.endDraw();
    return pg;
  }
  
  Task t = tasks.get(selectedTask);
  //actual graph
  ArrayList<String> resourceNames = new ArrayList<String>();
  for(int i = 0; i < t.slices.get(0).resources.size()-2; i++){
    resourceNames.add(t.slices.get(0).resources.get(i).name);
  }
  
  for(int i = 0; i < resourceNames.size(); i++){
    if(toggleGraphType){
      pg.noStroke();
      pg.fill(c_legend[getConflictIndex(resourceNames.get(i))], 255/resourceNames.size());
    }
    else{
      pg.noFill();
      pg.strokeWeight(2);
      pg.stroke(c_legend[getConflictIndex(resourceNames.get(i))]);
    }
    pg.beginShape();
    pg.vertex(10, h-10);
    for(int j = 0; j < t.slices.size(); j++){
      float timestamp = t.slices.get(j).timestamp;
      Resource r = t.slices.get(j).resources.get(i);
      pg.vertex(map(timestamp, t.getMinTime(), t.getMaxTime(), 10, w-10), 
                map(r.usage, 0, 1, h-10, 10));
    }
    pg.vertex(w-10, h-10);
    pg.endShape();
    pg.strokeWeight(1);
  }
  
  // timer bar on graph
  pg.stroke(c_maintimer, 150);
  pg.line(constrain(map(timer/timeScale, t.getMinTime(), t.getMaxTime(), 10, w-10),10,w-10),
          10, 
          constrain(map(timer/timeScale, t.getMinTime(), t.getMaxTime(), 10, w-10),10,w-10),
          h-10);

  float timestamp = t.slices.get(selectedSlice).timestamp;
  pg.stroke(c_mainslice, 150);
  pg.line(constrain(map(timestamp, t.getMinTime(), t.getMaxTime(), 10, w-10),10,w-10),
          10, 
          constrain(map(timestamp, t.getMinTime(), t.getMaxTime(), 10, w-10),10,w-10),
          h-10);
  
  //Axis and labels
  pg.textFont(smallFont, 10);
  pg.stroke(c_mainwhite);
  pg.line(8,0,8,h);
  pg.line(0,h-10, w, h-10);
  pg.stroke(c_mainwhite,50);
  pg.line(10,map(1., 0, 1, h-10, 10),w-10,map(1., 0, 1, h-10, 10));
  pg.line(10,map(.8, 0, 1, h-10, 10),w-10,map(.8, 0, 1, h-10, 10));
  pg.line(10,map(.6, 0, 1, h-10, 10),w-10,map(.6, 0, 1, h-10, 10));
  pg.line(10,map(.4, 0, 1, h-10, 10),w-10,map(.4, 0, 1, h-10, 10));
  pg.line(10,map(.2, 0, 1, h-10, 10),w-10,map(.2, 0, 1, h-10, 10));
  
  pg.fill(c_mainwhite); 
  pg.textAlign(LEFT, TOP);
  pg.text(int(t.getMinTime()), 11,h-9);
  if(t.getMaxTime()-t.getMinTime() > 2){
    pg.text(int((t.getMaxTime()+t.getMinTime())/2), w/2, h-9);
  }
  pg.textAlign(RIGHT, TOP);
  pg.text(int(t.getMaxTime()),w-10,h-9);
  
  pg.textAlign(RIGHT, BOTTOM);
  pg.text("1" ,7,10);
  pg.text(".8",7,map(.8, 0, 1, h-11, 10));
  pg.text(".6",7,map(.6, 0, 1, h-11, 10));
  pg.text(".4",7,map(.4, 0, 1, h-11, 10));
  pg.text(".2",7,map(.2, 0, 1, h-11, 10));
  pg.text("0" ,7,h-11);
  
  
  pg.endDraw();
  return pg;
}