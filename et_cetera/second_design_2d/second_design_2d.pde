float[] resources = {0.7, 0.2};

void setup(){
  size(600, 600);
  background(20);
  noFill();  
  textAlign(CENTER);
  
  textFont(createFont("Helvetica Neue LT Com 45 Light", 11));
}

void draw(){
  background(20);
  
  drawAxis(resources.length);
  drawShape(0.8, 0.5);
}

void drawShape(float workload, float risk){
  float maxRadius = width/2-width/8;
  float numLines = resources.length+2;
  
  stroke(200);
  fill(60, 40);
  beginShape();
  for(int i= 0; i < numLines; i++){
    if(i == 0)
      vertex(sin(2*PI/numLines*i)*maxRadius*workload, cos(2*PI/numLines*i)*maxRadius*workload);
    else if(i == int(numLines/2)) 
      vertex(sin(2*PI/numLines*i)*maxRadius*risk, cos(2*PI/numLines*i)*maxRadius*risk);
    else if(i < int(numLines/2))
      vertex(sin(2*PI/numLines*i)*maxRadius*resources[i-1], cos(2*PI/numLines*i)*maxRadius*resources[i-1]);
    else if(i > int(numLines/2))
      vertex(sin(2*PI/numLines*i)*maxRadius*resources[i-2], cos(2*PI/numLines*i)*maxRadius*resources[i-2]);  
  }
  endShape();
}

void drawAxis(float numRes){
  float numGrid = 5;
  float maxRadius = width/2-width/8;
  stroke(200, 50);
  translate(width/2, height/2);
  
  fill(60, 20);
  for(int i = 1; i < numGrid; i++){
    ellipse(0,0, maxRadius*i/2, maxRadius*i/2);
  }
  
  float numLines = numRes + 2;
  for(int i = 0; i < numLines; i++){
    line(0,0, sin(2*PI/numLines*i)*maxRadius*1.05, cos(2*PI/numLines*i)*maxRadius*1.05);
    String text = "";
    if(i == 0)
      text = "Workload"; 
    else if(i == int(numLines/2)) 
      text = "Risk";
    else
      text = "R"+i;
      
    fill(200, 100);  
    text(text, sin(2*PI/numLines*i)*maxRadius*1.15, 
               cos(2*PI/numLines*i)*maxRadius*1.15);
  }
  
}