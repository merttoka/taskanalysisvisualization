class Resource {
  public String name;
  public float usage;
  
  public Resource() {
    this.name = "";
    this.usage = 0.0;
  }
  public Resource(String s, float u){
    this.name = s;
    this.usage = u;
  }
}

class TaskSlice{
  private float timestamp;
  private float risk;
  private float diff;
  private ArrayList<Resource> resources;
  
  public TaskSlice() {
    this.resources = new ArrayList<Resource>();
  }
  public TaskSlice(float t, float r, float d){
    this.timestamp = t;
    this.risk = r;
    this.diff = d;
    this.resources = new ArrayList<Resource>();
  }
  public void assignResources(ArrayList<Resource> r){
    this.resources = r;
    
    // Risk and difficulty added to resource list ///for now///
    this.resources.add(new Resource("Risk", this.risk));
    this.resources.add(new Resource("Difficulty", this.diff));
    
  }
}

class Task {
  private String title;
  private ArrayList<TaskSlice> slices;
  public ArrayList<PShape> conflictingResources;
  public BBox bb;
  
  public Task() {
    this.title = "";
    this.slices = new ArrayList<TaskSlice>();
    this.conflictingResources= new ArrayList();
    this.bb = new BBox();
  }
  public Task(String t){
    this.title = t;
    this.slices = new ArrayList<TaskSlice>();
    this.conflictingResources= new ArrayList();
    this.bb = new BBox();
  }
  
  public String getTitle(){
    return title;
  }
  
  public void addSlice(float time, float risk, float diff, ArrayList<Resource> resources){
    TaskSlice slice = new TaskSlice(time, risk, diff); 
    slice.assignResources(resources);
    this.slices.add(slice);
  }
  
  public float getMinTime(){
    return slices.get(0).timestamp;
  }
  public float getMaxTime(){
    return slices.get(slices.size()-1).timestamp;
  }
  
  public void addConflictingResource(PShape p){
    conflictingResources.add(p);
  }
};

class BBox
{
  public PVector B1; //min vertex
  public PVector B2; //max vertex
  public PVector C;  //center vertex
  
  BBox()  {}
  BBox(PVector min, PVector max){
    this.B1 = min;
    this.B2 = max;
    this.C = new PVector((max.x-min.x)/2, (max.y-min.y)/2, (max.z-min.z)/2);
  }
  BBox(PVector min, PVector max, PVector cen){
    this.B1 = min;
    this.B2 = max;
    this.C = cen;
  }
  
  // returns true if line (L1, L2) intersects with the box (B1, B2)
  // returns intersection point in Hit
  public boolean CheckLineBox( PVector L1, PVector L2, PVector Hit)
  {
    if (L2.x < B1.x && L1.x < B1.x) return false; //<>// //<>// //<>//
    if (L2.x > B2.x && L1.x > B2.x) return false;
    if (L2.y < B1.y && L1.y < B1.y) return false;
    if (L2.y > B2.y && L1.y > B2.y) return false;
    if (L2.z < B1.z && L1.z < B1.z) return false;
    if (L2.z > B2.z && L1.z > B2.z) return false;
    if (L1.x > B1.x && L1.x < B2.x && L1.y > B1.y && L1.y < B2.y && L1.z > B1.z && L1.z < B2.z){
      Hit = L1;  
      return true;
    }
    
    if ( (GetIntersection( L1.x-B1.x, L2.x-B1.x, L1, L2, Hit) && InBox( Hit, 1 ))
      || (GetIntersection( L1.y-B1.y, L2.y-B1.y, L1, L2, Hit) && InBox( Hit, 2 )) 
      || (GetIntersection( L1.z-B1.z, L2.z-B1.z, L1, L2, Hit) && InBox( Hit, 3 )) 
      || (GetIntersection( L1.x-B2.x, L2.x-B2.x, L1, L2, Hit) && InBox( Hit, 1 )) 
      || (GetIntersection( L1.y-B2.y, L2.y-B2.y, L1, L2, Hit) && InBox( Hit, 2 )) 
      || (GetIntersection( L1.z-B2.z, L2.z-B2.z, L1, L2, Hit) && InBox( Hit, 3 )))
      return true;
      
    return false;
  }
  private boolean GetIntersection( float fDst1, float fDst2, PVector P1, PVector P2, PVector Hit) {
    if ( (fDst1 * fDst2) >= 0.0f) return false;
    if ( fDst1 == fDst2) return false; 
    PVector p = PVector.add(P1, PVector.mult(PVector.sub(P2, P1), -fDst1/(fDst2-fDst1)));
    Hit.x = p.x;
    Hit.y = p.y;
    Hit.z = p.z;
    
    return true;
  }
    
  private boolean InBox( PVector Hit, int Axis) {
    if ( Axis==1 && Hit.z > B1.z && Hit.z < B2.z && Hit.y > B1.y && Hit.y < B2.y) return true;
    if ( Axis==2 && Hit.z > B1.z && Hit.z < B2.z && Hit.x > B1.x && Hit.x < B2.x) return true;
    if ( Axis==3 && Hit.x > B1.x && Hit.x < B2.x && Hit.y > B1.y && Hit.y < B2.y) return true;
    return false;
  }
  
}