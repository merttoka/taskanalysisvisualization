class Task{ //<>//
  int resourceNum;
  float time;
  int[] whichResource;
  String title;
  
  boolean s;
  boolean e;
  
  float[] resources;
  float risk;
  float difficulty;
  
  Task(int r_num, float t, int[] w_r, String name, boolean start, boolean end){
    resourceNum = r_num;
    time = t;
    whichResource = w_r;
    title = name;
    s = start;
    e = end;
    
    resources = new float[resourceNum];
    /*risk = random(1);
    difficulty = random(1);*/
    risk = random(1.0/number*7.5);
    difficulty = random(1.0/number*7.5);
    for(int i = 0; i < resourceNum; i++){
      resources[i] = random(1.0/number*7.5);
    }
    for(int i = 0; i < resourceNum; i++){
       whichResource[i] = (int)random(1,6);
    }
  }
}
int number;
ArrayList<Task> arr;
boolean clicked = false;
void setup() {
  size(600, 200);
} //<>//

void draw(){
  background(20);
  
  fill(200);
  textAlign(CENTER, CENTER);
  textSize(25);
  text("Click here to generate random data", width/2, height/2-15);
  if(clicked){
    textSize(15);
    text(number + " tasks with average # of " + (int)arr.size()/number +" slices generated.", width/2, height/2+15);
  }
}

void mousePressed(){
  number = (int)random(10, 100);
  
  arr = new ArrayList<Task>();
  for(int i  = 0; i < number; i++){
    int n_slices = (int)random(3, 15);
    
    int resourceNum = (int)random(1,6);
    int[] whichResource = new int[resourceNum];
    float startTime = (int)random(0, 100);
    float endTime = (int)random(startTime+1, 120);
    float time = startTime;
    String title = "";
    float randLength = random(10, 35);
    for(int j = 0; j < randLength; j++){
      if(j == 3) title+= ' ';
      else if(j==4)title+= '-';
      else if(j==5)title+= ' ';
      else title += (char)(int)random(int('A'), int('Z'));
      
    }
    Task t = new Task(resourceNum, startTime, whichResource, title, true, false);
    arr.add(t);
    for(int j  = 0; j < n_slices-1; j++){
      time = startTime+(endTime-startTime)/n_slices*(j+1);
      arr.add(new Task(resourceNum, time, whichResource, title, false, false));
    }
    arr.add(new Task(resourceNum, endTime, whichResource, title, false, true));
  }
  
  Table table = new Table();
  
  table.addColumn("task_title");
  table.addColumn("time_stamp");
  table.addColumn("start_flag");
  table.addColumn("end_flag");
  table.addColumn("risk");
  table.addColumn("difficulty");
  table.addColumn("r_hardware");
  table.addColumn("r_software");
  table.addColumn("r_people");
  table.addColumn("r_consumables");
  table.addColumn("r_attire");
  table.addColumn("r_tools");
 
  
  for(int i = 0; i < arr.size(); i++){
    TableRow newRow = table.addRow();
    newRow.setString("task_title", arr.get(i).title);
    newRow.setFloat("time_stamp", arr.get(i).time);
    newRow.setInt("start_flag", arr.get(i).s == false ? 0: 1);
    newRow.setInt("end_flag", arr.get(i).e == false ? 0: 1);
    newRow.setFloat("risk", arr.get(i).risk);
    newRow.setFloat("difficulty", arr.get(i).difficulty);
    for(int j = 0; j < arr.get(i).resourceNum; j++){
      switch(arr.get(i).whichResource[j]){
        case 1:
          newRow.setFloat("r_hardware", arr.get(i).resources[j]); break;
        case 2:
          newRow.setFloat("r_software", arr.get(i).resources[j]); break;
        case 3:
          newRow.setFloat("r_people", arr.get(i).resources[j]); break;
        case 4:
          newRow.setFloat("r_consumables", arr.get(i).resources[j]); break;
        case 5:
          newRow.setFloat("r_attire", arr.get(i).resources[j]); break;
        case 6:
          newRow.setFloat("r_tools", arr.get(i).resources[j]); break;
        default: break;
      }
    }
  }

  saveTable(table, "./tasks.csv");
  
  clicked = true;
}