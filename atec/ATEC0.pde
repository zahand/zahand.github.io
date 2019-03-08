/* @pjs font="DroidSans-Basic.ttf,DroidSans-Bold-Basic.ttf"; 
 preload="eye.png, search.png, vignette.jpg"; 
 */

World w;
Ost[] osts;

Polygon[] lakes;
Polygon[] islands;
Polygon[] neighbors;
Polygon[] seas;

Polygon[] oilfields;
Polygon[] gasfields;
Polygon[] pipelines;

//Project[] projects;
Cluster[] clusters = new Cluster[0];

Project selP = null;
Ost selO = null; 
Cluster selC = null;

float detailsX, detailsY;
boolean refresh = false;
boolean idle = false;
boolean showMap = true;
boolean showGFields = showOFields = true;
boolean hGFields = hOFields = false;

PFont fontA, fontB;
int sFrameCount = 0;
int sFrameID;

void setup() { 
  size(960, 600);
  size(document.getElementById("viewport").offsetWidth, document.getElementById("viewport").offsetHeight);
  window.addEventListener("resize", doResizeShit);

  frameRate(30);
  noLoop();  
  fontA = createFont("DroidSans-Bold-Basic.ttf");
  fontB = createFont("DroidSans-Basic.ttf");
  textAlign(CENTER, CENTER);  
  textFont(fontA);  
  cursor(); 
  externals.context.lineCap="square";

  w = new World(); 
  loadMap();
  loadProjects();
  populateList();
  setPreCSS();

  w.z = w.pz = w.nz = 1;
  w.x = w.px = w.nx = width / 2 - w.w / 2;
  w.y = w.py = w.ny = height / 2 - w.h / 2;
  w.updateBB();

  mouseX = width/2;
  mouseY = height/2;

  filterProjects();

  externals.context.clearRect(0, 0, width, height);
  window.setTimeout(enter, 200);
}

void sLoop() {
  cancelAnimationFrame(sFrameID);
  sFrameID = requestAnimationFrame(sDraw);
}

void sDraw() {
  sFrameID = requestAnimationFrame(sDraw);
  refresh = false;  
  updateWorld();

  externals.context.clearRect(0, 0, width, height);
  drawMap();
  drawFields();  

  //  if (selP != null) {
  //    fill(255, 150);
  //    noStroke();
  //    rect(0, 0, width, height);
  //  }     

  //  drawPipelines();
  drawClusters(); 
  for (Ost o : osts) o.drawLabels();
  drawProjects(); 
  if (selC != null) selC.drawPie();   
  if (selP != null) selP.draw();

  //  fill(255);
  //  text(sFrameCount, 30, 20);
  //  text("w.nx: " + w.nx + " w.ny: " + w.ny + " w.nz: " + w.nz, width/2, 20);
  //  text("w.pz: " + w.pz, 130, 40);
  //  text("w.z: " + w.z, width/2, 60);
  //  text("w.w: " + w.w, width/2, 80);
  //  text("w.nz: " + w.nz, 130, 80);

  sFrameCount += 1;  
//  println(sFrameCount);
  if (refresh == false) cancelAnimationFrame(sFrameID);
}

void updateWorld() {
  w.update();
  if (((w.nz-w.z) / (w.nz-w.pz)) < .1 && w.newZ) {
    clusterProjects();
    w.newZ = false;
  }
}

void drawMap() {
  if (showMap) {
    cFill(WATER_FILL);  
    for (Polygon s : seas) s.renderInfinite(true, false, true);  

    cFill(BACKGROUND);
    for (Polygon i : islands) i.render(true, false, true);

    cStrokeWeight(.75);
    cStroke(NEIGH_STROKE);
    for (Polygon n : neighbors) n.renderInfinite(false, true, false);
  }
  for (Ost o : osts) if (w.bb.containsBox(o.bb)) o.drw(showMap);

  if (showMap) { 
    if (selO != null) selO.drawStroke();
    cFill(WATER_FILL);
    cStroke(OST_STROKE);  
    cStrokeWeight(.5);  
    for (Polygon l : lakes) l.render(true, true, true);
  }
}  

void drawProjects() {
  for (Project p : projects) {
    if (p != selP) p.draw();
  }
}

void drawClusters() {
  for (Cluster c : clusters) {
    //c.draw();    
    c.drawPie();
  }
}

void drawPipelines() {
  cStroke(PIPE);
  cStrokeWeight(2);
  for (Polygon p : pipelines) p.renderDashed(false, true, false);    
  cStrokeWeight(4);  
  for (Polygon p : pipelines) p.renderDotted(false, true, false);
}

void drawFields() {
  int times = 1;
  cStrokeWeight(.5);

  if (showGFields) {
    cStroke(GAS);
    times = (hGFields) ? 3 : 1;
    for (int i = 0; i < times; i++) {
      for (Polygon f : gasfields) {
        cHatch(f.hatch);    
        f.renderCrv(true, true, true);
      }
    }
  }
  if (showOFields) { 
    cStroke(OIL); 
    times = (hOFields) ? 3 : 1;
    for (int i = 0; i < times; i++) {    
      for (Polygon f : oilfields) {
        cHatch(f.hatch);    
        f.renderCrv(true, true, true);
      }
    }
  }
}

void keyPressed() {
  if (key == 's') save();
  if (key == 'x') scrollbar2.update();
}

void doResizeShit() {
  size(document.getElementById("viewport").offsetWidth, document.getElementById("viewport").offsetHeight);
  zoomExt();
  setPreCSS();
  sLoop();
}

void draw() {
}

void cFill(Color c){
	externals.context.fillStyle = "rgba("+((c >> 16) & 0xFF)+","+((c >> 8) & 0xFF)+","+(c & 0xFF)+","+(((c >> 24) & 0xFF)/255.0)+")";
}
void cFillAlpha(Color c,float a){
	externals.context.fillStyle = "rgba("+((c >> 16) & 0xFF)+","+((c >> 8) & 0xFF)+","+(c & 0xFF)+","+a+")";
}
void cStroke(Color c){
	externals.context.strokeStyle = "rgba("+((c >> 16) & 0xFF)+","+((c >> 8) & 0xFF)+","+(c & 0xFF)+","+(((c >> 24) & 0xFF)/255.0)+")";
}
void cStrokeWeight(float f){
	externals.context.lineWidth = f;
}
void cHatch(var hatch){
	externals.context.fillStyle = hatch;
}
void cStrokeJoin(String s) {
	externals.context.lineJoin = s;
}
String cssColor(Color c){
	String cssColor = "rgba("+((c >> 16) & 0xFF)+","+((c >> 8) & 0xFF)+","+(c & 0xFF)+","+(((c >> 24) & 0xFF)/255.0)+")";
	return cssColor;
}
class Cluster {
  float x, y, r;
  int count;
  BBox bb;
  Project[] children;

  Cluster() {
    children = new Project[0];
    x = y = r = count = 0;
    bb = null;
  }

  void draw() {
    float _x = w.w2sX(x);
    float _y = w.w2sY(y);
    pushStyle();
    stroke(CLUSTER_STROKE);
    strokeWeight(1.5); 
    fill(CLUSTER_FILL);
    if (count > 0) ellipse(_x, _y, r, r);
    stroke(CLUSTER_STROKE, 128);
    strokeWeight(1); 
    for (Project p : children) {
      beginShape();
      vertex(_x, _y);
      vertex(w.w2sX(p.x), w.w2sY(p.y));
      endShape();
    }
    popStyle();
  }

  void drawPie() {
    float _x = w.w2sX(x);
    float _y = w.w2sY(y);
    float s = r/4;
    float d = r - s + 4;
    float t = TWO_PI / count;
    pushStyle();
    noStroke();
    if (count > 1) {
//      stroke(CLUSTER_LINES);
//      strokeWeight(1); 
//      for (Project p : children) {
//        beginShape();
//        vertex(_x, _y);
//        vertex(w.w2sX(p.x), w.w2sY(p.y));
//        endShape();
//      }
//      stroke(255);
//      strokeWeight(s); 
      fill(CLUSTER_PIE_FILL);
      ellipse(_x, _y, r - s*2 + 8, r - s*2 + 8);
    } else {
      Project p = children[0];
      fill(brighten(p.col1));
      ellipse(w.w2sX(p.x), w.w2sY(p.y), 12, 12);
    }
    noFill();
    strokeWeight(s);
    strokeCap(SQUARE); 
    float gap = -.01 ;   
    for (int i = 0; i < count; i++) {
      stroke(children[i].col1);
      arc(_x, _y, d, d, t*i + gap, t * (i+1) - gap);
    }  
    popStyle();
  }
}

void clusterProjects() {
  selC = null;
  while (clusters.length > 0) clusters.pop();
  int maxCount = 1;
  for (Project p : projects) {
    if (!p.active) continue;
    Cluster newC = null;
    float minD = 1000000;
    for (Cluster c : clusters) {
      float d = dist(p.x, p.y, c.x, c.y);
      if (d < minD && d > 0) {
        minD = d;
        if (d < (32 / w.nz)) newC = c;
      }
    }
    if (newC == null) {
      newC = new Cluster();
      newC.x = p.x;
      newC.y = p.y;
      newC.children.push(p);
      newC.count = 1;
      newC.bb = new BBox();          
      newC.bb.x = p.x;
      newC.bb.y = p.y;
      newC.bb.w = p.x;
      newC.bb.h = p.y;  
      clusters.push(newC);
    } else {
      newC.children.push(p);
      newC.count += 1;      
      var t = 1/newC.count;      
      newC.x = lerp(newC.x, p.x, t);
      newC.y = lerp(newC.y, p.y, t);
      if (p.x < newC.bb.x) newC.bb.x = p.x;
      else if (p.x > newC.bb.w) newC.bb.w = p.x;
      if (p.y < newC.bb.y) newC.bb.y = p.y;
      else if (p.y > newC.bb.h) newC.bb.h = p.y;
      if (newC.count > maxCount) maxCount = newC.count;
    }
  }
  for (Cluster c : clusters) {
    c.r = sqrt(c.count/projects.length) * 150;
    c.bb.x -= 4/w.nz;
    c.bb.w += 4/w.nz;
    c.bb.y -= 4/w.nz;
    c.bb.h += 4/w.nz;     
    c.bb.w = c.bb.w - c.bb.x;
    c.bb.h = c.bb.h - c.bb.y;
  }
}

color CAT0 = color(255, 198, 0);
color CAT1 = color(71, 179, 165);
color CAT2 = color(140, 214, 0);
color CAT3 = color(255, 63, 35);

color BACKGROUND = color(255,255,255);//color(55, 59, 68);

color WATER_FILL = color(235);//color(35, 38, 47);

color NEIGH_STROKE = color(180);//color(80, 83, 91);

color OST_FILL = color(50);//color(92, 98, 112);
color OST_FILL_MIN = color(55, 59, 68);
color OST_FILL_MAX = color(92, 98, 112);
color OST_STROKE = color(0,128);//color(142, 148, 167);
color OST_TEXT = color(255);
color OST_BG = color(240);

color CLUSTER_FILL = color(255,128);//color(41, 44, 54, 180);
color CLUSTER_STROKE = color(255,180);//color(255, 180);
color CLUSTER_LINES = color(0,180);//color(255, 180);

color CLUSTER_PIE_FILL = color(255,128);//color(41, 44, 54, 128);
color CLUSTER_PIE_TEXT = color(255, 180);

color OIL = color(0,198);//color(71, 179, 165);
color GAS = color(0,198);//color(140, 214, 0);
color PIPE = color(0,128);//color(255, 140);

color RED = color(255,0,0);

color brighten(color c) {
  float r = ((c >> 16) & 0xFF) / 255.0f;
  float g = ((c >> 8) & 0xFF) / 255.0f;
  float b = (c & 0xFF) / 255.0f;
  r = sqrt(r);
  g = sqrt(g);
  b = sqrt(b);
  return color(255*r, 255*g, 255*b);
}

color setAlpha(color c, int a) { 
  return ((c & 0xffffff) | (a << 24));
}
class Polygon {
  public PVector[] verts;
  String label;
  var sprite;
  var hatch;
  int lod;
  PVector centroid;

  Polygon() {
    verts = null;
    sprite = null;
    hatch = null;
    lod = 0;
  }

  boolean containsPoint(float _x, float _y) {
    int num = verts.length;
    int i, j = num - 1;
    boolean oddNodes = false;
    float px = _x;
    float py = _y;
    for (i = 0; i < num; i++) {
      PVector vi = verts[i];
      PVector vj = verts[j];
      if (vi.y < py && vj.y >= py || vj.y < py && vi.y >= py) {
        if (vi.x + (py - vi.y) / (vj.y - vi.y) * (vj.x - vi.x) < px) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }
    return oddNodes;
  }

  PVector getCentroid() {
    PVector res = new PVector();
    for (int i = 0, num = verts.length; i < num; i++) {
      PVector a = verts[i];
      PVector b = verts[(i + 1) % num];
      float crossP = a.x * b.y - b.x * a.y;
      res.x += (a.x + b.x) * crossP;
      res.y += (a.y + b.y) * crossP;
    }
    res.mult(1f / (6 * getArea()));
    return res;
  }

  float getArea() {
    float area = 0;
    for (int i = 0, num = verts.length; i < num; i++) {
      PVector a = verts[i];
      PVector b = verts[(i + 1) % num];
      area += a.x * b.y;
      area -= a.y * b.x;
    }
    area *= 0.5f;
    return area;
  }

  void bakeLabel() {
    if (label != null) {
      var sub = (lod > 0)
      var txtSize = (sub) ? 12 : 16;
      var font = (sub) ? (txtSize + "px DroidSans-Basic") : ("bold " + txtSize + "px DroidSans-Bold-Basic");
      var tmp = document.createElement("canvas");
      tmp.width=0;
      tmp.height=0;
      var t = tmp.getContext("2d");
      t.font = font;
      var wid = t.measureText(label).width;

      sprite = document.createElement("canvas");
      sprite.width=wid+4;
      sprite.height=txtSize*2;

      var ctx = sprite.getContext("2d");
      ctx.font = font;
      ctx.fillStyle = "#" + hex(OST_TEXT, 6);
      ctx.textBaseline = "top";
      ctx.fillText(label, 0, 0);
    }
  }

  void bakeHatch(int _w, int _h, float lw, float x1, float y1, float x2, float y2, String col) {
    var tmp = document.createElement("canvas"); 
    tmp.width = _w;
    tmp.height = _h;
    var ctx = tmp.getContext("2d");
    ctx.strokeStyle = col;
    ctx.lineWidth = lw;
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
    hatch = externals.context.createPattern(tmp, "repeat");
  } 

  void bakeHatchFixed(int _w, int _h, float lw, String col) {
    var tmp = document.createElement("canvas"); 
    tmp.width = _w;
    tmp.height = _h;
    var ctx = tmp.getContext("2d");
    ctx.strokeStyle = col;
    ctx.lineWidth = lw;
    ctx.beginPath();
    ctx.moveTo(0, _h/2);
    ctx.lineTo(_w/2, 0);
    ctx.moveTo(_w/2, _h);
    ctx.lineTo(_w, _h/2);
    ctx.stroke();
    hatch = externals.context.createPattern(tmp, "repeat");
  } 

  void renderDotted() {
    externals.context.beginPath();
    for (int i = 0; i < verts.length; i++) {
      externals.context.moveTo(w.w2sX(verts[i].x), w.w2sY(verts[i].y));
      externals.context.lineTo(w.w2sX(verts[i].x), w.w2sY(verts[i].y)+0.01);
    }
    externals.context.stroke();
  }

  void renderDashed() {
    externals.context.beginPath();
    for (int i = 0; i < verts.length-1; i++) {
      externals.context.moveTo(w.w2sX(verts[i].x), w.w2sY(verts[i].y));
      if (i%2==0) externals.context.lineTo(w.w2sX(verts[i+1].x), w.w2sY(verts[i+1].y));
    }
    externals.context.stroke();
  }

  void render(boolean _fill, boolean _stroke, boolean _close) {
    externals.context.beginPath();
    externals.context.moveTo(w.w2sX(verts[0].x), w.w2sY(verts[0].y));
    for (int i = 1; i < verts.length; i++) {
      externals.context.lineTo(w.w2sX(verts[i].x), w.w2sY(verts[i].y));
    }
    if (_close) externals.context.closePath();
    if (_fill) externals.context.fill();
    if (_stroke) externals.context.stroke();
  } 

  void renderCrv(boolean _fill, boolean _stroke, boolean _close) {
    externals.context.beginPath();
    int i = 0;
    float xs = (w.w2sX(verts[i].x) + w.w2sX(verts[i+1].x)) / 2;
    float ys = (w.w2sY(verts[i].y) + w.w2sY(verts[i+1].y)) / 2;
    externals.context.moveTo(xs, ys);
    for (i = 1; i < verts.length - 1; i++) {
      float xc = (w.w2sX(verts[i].x) + w.w2sX(verts[i+1].x)) / 2;
      float yc = (w.w2sY(verts[i].y) + w.w2sY(verts[i+1].y)) / 2;
      externals.context.quadraticCurveTo(w.w2sX(verts[i].x), w.w2sY(verts[i].y), xc, yc);
    }
    externals.context.quadraticCurveTo(w.w2sX(verts[0].x), w.w2sY(verts[0].y), xs, ys);
    if (_fill) externals.context.fill();
    if (_stroke) externals.context.stroke();
  } 

  void renderInfinite(boolean _fill, boolean _stroke, boolean _close) {
    externals.context.beginPath();
    float x = verts[0].x;
    float y = verts[0].y;
    if (x > w.w + w.w) x = width;
    else if (x < -w.w) x = 0;
    else x = w.w2sX(x);
    if (y > w.h + w.h) y = height;
    else if (y < -w.h) y = 0;
    else y = w.w2sY(y);
    externals.context.moveTo(x, y);
    for (int i = 1; i < verts.length; i++) {
      x = verts[i].x;
      y = verts[i].y;
      if (x > w.w + w.w) x = width;
      else if (x < -w.w) x = 0;
      else x = w.w2sX(x);
      if (y > w.h + w.h) y = height;
      else if (y < -w.h) y = 0;
      else y = w.w2sY(y);    
      externals.context.lineTo(x, y);
    }
    if (_close) externals.context.closePath();
    if (_fill) externals.context.fill();
    if (_stroke) externals.context.stroke();
  }
}

class BBox {
  float x = MAX_INT;
  float y = MAX_INT;
  float w = -MAX_INT;
  float h = -MAX_INT;

  boolean containsPoint(float _x, float _y) {
    boolean does = _x > x && _x < x+w && _y > y && _y < y+h;
    return does;
  }  

  boolean containsBox(BBox b) {
    boolean does = b.x < x+w && b.y < y+h && b.x+b.w > x && b.y+b.h > y;
    return does;
  }
}

void rectangle(float _x, float _y, float _w, float _h) {
  beginShape();
  vertex(_x, _y);
  vertex(_x + _w, _y);
  vertex(_x + _w, _y + _h);
  vertex(_x, _y + _h);
  endShape();
}  

float[] findPositionOnBezier(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4, float t) {
  float [] out = new float[] {
    0, 0
  };
  double mu, mum1, mum13, mu3;
  mu = t;
  mum1 = 1 - mu;
  mum13 = mum1 * mum1 * mum1;
  mu3 = mu * mu * mu;
  out[0] = (float) ( mum13*x1 + 3*mu*mum1*mum1*x2 + 3*mu*mu*mum1*x3 + mu3*x4 );
  out[1] = (float) ( mum13*y1 + 3*mu*mum1*mum1*y2 + 3*mu*mu*mum1*y3 + mu3*y4 );
  return out;
}

void setPreCSS() {
  var precss = document.getElementById("precss");
  if (precss) document.head.removeChild(precss);

  var c0 = "#"+hex(CAT0, 6);
  var c1 = "#"+hex(CAT1, 6);
  var c2 = "#"+hex(CAT2, 6);
  var c3 = "#"+hex(CAT3, 6);
  var c0b = "#"+hex(brighten(CAT0), 6);
  var c1b = "#"+hex(brighten(CAT1), 6);
  var c2b = "#"+hex(brighten(CAT2), 6);
  var c3b = "#"+hex(brighten(CAT3), 6);

  //var dw = int(min(height * 1, .5 * width));
  dw = int(width / 2.5);
  var cssText = 
    //"#details {width: " + dw + "px; left: -" + (dw + 150) + "px;}" +
    "#details {width: " + dw + "px;}" + 
    ".cat0 {background-color: " + c0 + ";}" +
    ".cat1 {background-color: " + c1 + ";}" +
    ".cat2 {background-color: " + c2 + ";}" +
    ".cat3 {background-color: " + c3 + ";}" +
    "input[type=checkbox]:checked + .cat0{background-color: " + c0 + ";}" + 
    "input[type=checkbox]:checked + .cat1{background-color: " + c1 + ";}" + 
    "input[type=checkbox]:checked + .cat2{background-color: " + c2 + ";}" + 
    "input[type=checkbox]:checked + .cat3{background-color: " + c3 + ";}" +
    "input[type=checkbox] + .cat0:hover{background-color: " + c0b + ";}" +
    "input[type=checkbox] + .cat1:hover{background-color: " + c1b + ";}" + 
    "input[type=checkbox] + .cat2:hover{background-color: " + c2b + ";}" +
    "input[type=checkbox] + .cat3:hover{background-color: " + c3b + ";}" +
    ".button.c0:hover ~ label .toggle{background-color:" + c0b + ";}" +
    ".button.c1:hover ~ label .toggle{background-color:" + c1b + ";}" +
    ".button.c2:hover ~ label .toggle{background-color:" + c2b + ";}" +
    ".button.c3:hover ~ label .toggle{background-color:" + c3b + ";}";

  var w1 = localBoundingRect(document.getElementById("menu1")).width;
  var w2 = localBoundingRect(document.getElementById("menu2")).width;

//  if (width - w1 - w2 < height * 0) {
  if (width - w1 - w2 < 0) {    
    cssText += "#menu1{left:-"+(w1-28)+"px; height: " + height +"px;}"; 
    //cssText += "#menu1 .toggle{color:rgba(0,0,0,1)}#menu1 .button{color:rgba(255,255,255,1)}";
  } else cssText += "#menu1{left:0px; height: " + height +"px;}"; //#menu1 .toggle{color:rgba(0,0,0,1)}#menu1 .button{color:rgba(255,255,255,1)}";

  precss = document.createElement("style");
  precss.type = "text/css";
  precss.id = "precss";  
  precss.appendChild(document.createTextNode(cssText));
  document.head.appendChild(precss);

  detailsX = round(.5 * width);
  updateScrollBar(scrollbar, document.getElementById("art"));
  updateScrollBar(scrollbar2, document.getElementById("projectlist"));
}

void updatescroll() {
  updateScrollBar(scrollbar, document.getElementById("art"));
}

void updatescroll2() {
  updateScrollBar(scrollbar2, document.getElementById("projectlist"));
}

void updateScrollBar(Object bar, Object elem) {
  bar.update();
  if (bar.contentRatio < 1) elem.className = "scrolling";
  else elem.className = "";
  bar.update();
}

void showTooltip(Project p) {
  var tooltip = document.getElementById("tooltip");  
  if (p == null) {
    tooltip.className = "hid";
  } else {
    tooltip.className = "cat" + p.cat; 
    tooltip.innerHTML = p.name;
    setTooltipPos(p);
  }
}

void showTooltipC(Cluster c) {
  var tooltip = document.getElementById("tooltip");  
  if (c == null) {
    tooltip.className = "hid";
  } else {
    tooltip.className = "vis"; 
    tooltip.innerHTML = c.count + " Projects";
    setTooltipPos(c);
  }
}

/*
void showTooltipString(String s) {
  var tooltip = document.getElementById("tooltip");  
  if (s == null) {
    tooltip.className = "hid";
  } else {
    tooltip.className = "vis"; 
    tooltip.innerHTML = s;
    setTooltipPos();
  }
}
*/

void setTooltipPos(Object p) {
  var tooltippos = document.getElementById("tooltippos");
  if (p instanceof Project) {
    tooltippos.style.top = (w.w2sY(p.y) - 9) + "px"; 
    if (mouseX < width / 2) {
      tooltippos.style.left = w.w2sX(p.x) + "px"; 
      tooltippos.style.right = "";  
      tooltip.style.left = 16 + "px";
      tooltip.style.right = "";
    } else {
      tooltippos.style.right = (width - w.w2sX(p.x)) + "px";   
      tooltippos.style.left = "";
      tooltip.style.left = "";
      tooltip.style.right = 16 + "px";
    }
  } else if (p instanceof Cluster) {
    tooltippos.style.top = (w.w2sY(p.y) - 9) + "px"; 
    if (mouseX < width / 2) {
      tooltippos.style.left = w.w2sX(p.x) + "px"; 
      tooltippos.style.right = "";  
      tooltip.style.left = p.r/2 + 8 + "px";
      tooltip.style.right = "";
    } else {
      tooltippos.style.right = (width - w.w2sX(p.x)) + "px";   
      tooltippos.style.left = "";
      tooltip.style.left = "";
      tooltip.style.right = p.r/2 + 8 + "px";
    }
  }
}

boolean md = false;
int mx0, my0;

void mouseScrolled() {
  float newZ = (mouseScroll > 0) ? w.nz * 1.25 : w.nz * .8;
  newZ = constrain(newZ, .5, 500); 
  zoom(mouseX, mouseY, newZ);
  sLoop();
}

void mouseMoved() {
  if (mouseX != pmouseX || mouseY != pmouseY) {
    float x = w.s2wX(mouseX);
    float y = w.s2wY(mouseY);  
    selC = null;
    for (Cluster c : clusters) {
      float s = c.r/w.z;
      if (dist(x, y, c.x, c.y) < (.5*s)) {
        selC = c;
      }
    }
    if (selC != null) {
      if (selC.count == 1) showTooltip(selC.children[0]);
      //else showTooltipString(selC.count + " Projects");
      else showTooltipC(selC);
      cursor(HAND);
    } else {
      showTooltip(null);
      cursor();
    }

    for (Ost o : osts) {
      o.hovered = false;
      if (selC == null && selP == null && selO == null) {
        if (o.containsPoint(x, y)) o.hovered = true;
      }
    }
    sLoop();
  }
}

void mousePressed() {
  md = false;
  mx0 = mouseX;
  my0 = mouseY;
}

void mouseDragged() {
  if (!md) {
    if (mx0 != mouseX || my0 != mouseY) md = true;
    if (md) cursor(MOVE);
  } 
  float dx = (mouseX-pmouseX)/w.z;
  float dy = (mouseY-pmouseY)/w.z;
  if (dx > 0) { if (w.nx * w.z < .5 * width) w.nx += dx; } 
  else { if (w.nx > .5 * width / w.z - w.w) w.nx += dx; } 
  if (dy > 0) { if (w.ny * w.z < .5 * height) w.ny += dy; } 
  else { if (w.ny > .5 * height / w.z - w.h) w.ny += dy; }  
  showTooltip(null);
  sLoop();
}

void mouseOut() {
  mousePressed = false;
}

void mouseReleased() {
  showTooltip(null);
  if (md) {
    cursor();
    md = false;
  } else {
    if (mouseButton == RIGHT) {zoomExt(); sLoop(); showTooltip(null); cursor(); return;}
    float x = w.s2wX(mouseX);
    float y = w.s2wY(mouseY);  
    checkHover(x,y);

    if (selC != null) {
      if (selC.count == 1) {
        Project p = selC.children[0];
        selectProject(p);
      } else {
        zoomWinFree(selC.bb.x, selC.bb.y, selC.bb.w, selC.bb.h);
      }
      sLoop();
      showTooltip(null);
      cursor();
      return;
    } else {
      if (selP != null) {
        selectProject(null);
        showTooltip(null);
        cursor();
        sLoop();
        return;
      }
    }

    if (selO != null) {
      selO.selected = false;
      selO = null;
      } else {
      for (Ost o : osts) {
        o.hovered = false;
        if (o.containsPoint(x, y)) {
          o.selected = true;
          selO = o;
        } else {
          o.selected = false;
        }
      }
    }
    if (selO == null) zoomExt();
    else zoomWin(selO.bb.x, selO.bb.y, selO.bb.w, selO.bb.h);
    filterProjects();     
    sLoop();
  }
}

void checkHover(float x,float y){
  selC = null;
  for (Cluster c : clusters) {
    float s = c.r/w.z;
    if (dist(x, y, c.x, c.y) < (.5*s)) {
      selC = c;
    }
  }
  if (selC != null) {
    if (selC.count == 1) showTooltip(selC.children[0]);
    //else showTooltipString(selC.count + " Projects");
    else showTooltipC(selC);
    cursor(HAND);
    return;
  } else {
    showTooltip(null);
    cursor();
  }
}
class Ost {
  Polygon[] polys, plines;
  int id;
  boolean hovered, selected;
  BBox bb;
  float anim;

  Ost() {
    polys = new Polygon[0];
    plines = new Polygon[0];

    bb = null;
    hovered = false;
    selected = false;
    anim = 0;
  }

  void drw(boolean boo) {
    if (selected) { 
      anim = animate(anim, 1, .05);
    } else if (hovered) { 
      anim = animate(anim, .7, .05);
    } else {
      anim = animate(anim, 0, .05);
    }    
    cStrokeWeight(.5);  
    cStroke(OST_STROKE);
    cFill(setAlpha(OST_FILL,anim*255));
    for (Polygon poly : polys) poly.render((anim != 0), boo, true);
    
    if (anim > 0) {
      cStroke(setAlpha(BACKGROUND, 50));
      cStrokeWeight(1);          
      for (Polygon pline : plines) pline.render(false, true, false);
    }
    
  }

  void drwBG() {
    for (Polygon p : polys) {
        cHatch(p.hatch);    
        p.render(true, true, true);
      }
  }
  
  void drawStroke() {
    cStrokeWeight(1.5);
    cStroke(OST_STROKE);
    cStrokeJoin("bevel");
    for (Polygon poly : polys) poly.render(false, true, true);;
  }

  void drawLabels() {
    if (anim == 0) return;  
    for (Polygon poly : polys) {
      if (poly.sprite != null && poly.lod  <= ceil(w.z)) {
        PVector c = poly.centroid; 
        var s = poly.sprite;          
        float _x = w.w2sX(c.x) - (s.width/2);
        float _y = w.w2sY(c.y);
        if (poly.lod == 0) _y -= (s.height/4);          
        externals.context.globalAlpha=anim*.65;
        externals.context.drawImage(s,_x,_y);
        externals.context.globalAlpha=1;
      }
    }
  }

  boolean containsPoint(float mx, float my) {
    if (bb.containsPoint(mx, my)) {
      for (Polygon poly : polys) 
        if (poly.containsPoint(mx, my)) return true;
    }
    return false;
  }
}

void toggleMap(boolean bool){
  showMap = bool;
}

void highlightFields(int value) {
  if (value == 0) {
    hGFields = false; 
    hOFields = false;
  } else if (value == 1) hGFields = true;
  else if (value == 2) hOFields = true;
}

void toggleFields(int value, boolean bool){
  if (value == 1) showGFields = bool;
  else showOFields = bool;
}

void loadMap() {
  try {
    String[] linez = loadStrings("mapV1NoZero.txt");
  } catch (Exception E) {
    println("map " + E);
    fakeMap();
    return;
  }
  float ratio = float(linez[0]);

  w.w = .75 * min(width, height);
  w.h = w.w * ratio; 

  osts = new Ost[31];
  seas = new Polygon[0];
  lakes = new Polygon[0];
  islands = new Polygon[0];
  oilfields = new Polygon[0];
  gasfields = new Polygon[0];
  pipelines = new Polygon[0];  
  neighbors = new Polygon[0];

  for (int i = 1; i < linez.length; i++) {
    String[] cpts = split(linez[i], ';');
    float minX = MAX_INT;
    float maxX = -MAX_INT;
    float minY = MAX_INT;
    float maxY = -MAX_INT;
    int id = int(cpts[0]);

    Polygon p = new Polygon();
    p.verts = new PVector[cpts.length - 2];
    p.label = cpts[1];
    for (int j = 2; j < cpts.length; j++) {
      float[] xy = float(split(cpts[j], ','));
      float _x = xy[0];
      float _y = (1-xy[1]);
      _x *= w.w;
      _y *= w.h;
      if (_x < minX) minX = _x;
      if (_x > maxX) maxX = _x;
      if (_y < minY) minY = _y;
      if (_y > maxY) maxY = _y;            
      p.verts[j-2] = (new PVector(_x, _y));
    }

    if (id < 50) {

      if (osts[id-1] == null) {
        Ost o = new Ost();  
        o.id = id;
        o.bb = new BBox();          
        o.bb.x = minX;
        o.bb.y = minY;
        o.bb.w = maxX - minX;
        o.bb.h = maxY - minY;  

        p.centroid = p.getCentroid();        
        if (p.label == "Hormozgan") p.centroid.add(-10, -25); 
        p.bakeLabel();
//        p.bakeHatchFixed(6, 6, 1, cssColor(OST_FILL));
        o.polys.push(p);
        osts[id-1] = o;
      } else { 
        p.lod = 3; 
        if (p.label == "0") {
          osts[id-1].plines.push(p);
        } else {
          p.centroid = p.getCentroid(); 
          if (p.label == "none") p.label = null; 
          else if (p.label != "Qeshm") p.centroid.add(0, 2);
          else p.centroid.add(4, -3); 
          p.bakeLabel();
          osts[id-1].polys.push(p);
          islands.push(p);
        }
      }
    } else {
      if (id == 100) seas.push(p);
      else if (id == 200) lakes.push(p);
      else if (int(id/100) == 3) neighbors.push(p);
      else if (int(id/100) == 4) {
        p.bakeHatchFixed(6, 6, 1, cssColor(OIL));
        oilfields.push(p);
      }
      else if (int(id/100) == 5) {
        p.bakeHatch(3, 3, 2, 0, 0, 1, 1, cssColor(GAS));
        gasfields.push(p);
      }
      else if (id == 600) {
        pipelines.push(p);
      }
    }
  }
}  

void fakeMap() {
  w.w = .9 * min(width, height);
  w.h = w.w * 0.918811; 
  osts = new Ost[1];
  seas = new Polygon[0];
  lakes = new Polygon[0];
  islands = new Polygon[0];
  oilfields = new Polygon[0];
  gasfields = new Polygon[0];
  pipelines = new Polygon[0];  
  neighbors = new Polygon[0];
  Polygon p = new Polygon();
  p.verts = new PVector[5];
  p.verts[0] = new PVector(0, 0);
  p.verts[1] = new PVector(w.w, 0);
  p.verts[2] = new PVector(w.w, w.h);
  p.verts[3] = new PVector(0, w.h);
  p.verts[4] = new PVector(0, 0);
  p.label = "Error: Map Not Found";
  p.centroid = p.getCentroid(); 
  p.bakeLabel();
  Ost o = new Ost();  
  o.id = 0;
  o.bb = new BBox();          
  o.bb.x = 0;
  o.bb.y = 0;
  o.bb.w = w.w;
  o.bb.h = w.h;   
  o.polys.push(p);
  osts[0] = o;
  seas[0] = p; 
  lakes.push(p);
  islands.push(p);
  neighbors.push(p);
  gasfields.push(p);
  oilfields.push(p);
  seas[0].bakeHatch(3, 2, 1, 2, 0, 2, 2, "#111");
}
class Project {
  float x, y, N, E, lx, ly, cx, cy, r;
  String name;
  String[] details;
  boolean selected, active, linkDet, linkVir, linkCat, linkList;
  boolean[] filter;
  int cat, pid, z;
  color col1, col2;

  Project() {
    filter = new boolean[11];
    details = new String[11];
    selected = false;
    active = true;
    cat = -1;
    z = 12;
  }

  void draw() {
    pushStyle();
    noStroke();
    float _x = w.w2sX(x);
    float _y = w.w2sY(y);
    float diam = r;

    if (active || selected) {        
      if (selected) { 
        fill(col2); 
        diam += 8;
      } else {
        fill(col1);
      }
    } else {
      fill(CLUSTER_STROKE); 
      diam = 4;
    }

    ellipse(_x, _y, diam, diam);    
    drawLinks(_x, _y);
    popStyle();
  }

  void drawLinks(float _x, float _y) {
    if (linkCat || (filterOn && active)) {
      stroke(col1);
      noFill();
      strokeWeight(2);
      float x1, y1, x2, y2;
      boolean uturn = (_x < cx + 4);
      boolean outsideX = uturn || _x > width;
      boolean outsideY = _y > height || _y < 0;
      boolean steep = (uturn) ? false : (abs(_x - (cx + 50)) < abs(_y - cy)) || outsideY;
      float u = max(cx + 4, min(width - 4, _x));
      float v = max(4, min(height - 4, _y)); 
      if (steep) {
        if (!outsideY) v = (v > cy) ? v - 8 : v + 8;
        if (outsideX) u = u - 4;
        x1 = u;
        y1 = v - (v - cy) / 2;
        x2 = cx + max(100, (u - cx)/2);
        y2 = cy;
      } else {
        float d = (uturn) ? max(50, abs(v-cy)) : 50;
        if (outsideY) v = (v > cy) ? v - 4 : v + 4;
        if (!outsideX) u = (u > cx + d) ? u - 8 : u + 8;
        x1 = max(cx + d, u - (u - cx) / 2);
        y1 = v;
        x2 = cx + max(d, (u - cx)/2);
        y2 = cy;
      }
      beginShape();
      vertex(u, v);
      bezierVertex(x1, y1, x2, y2, cx, cy);
      vertex(0, cy);
      endShape();
      strokeWeight(4);
      strokeCap(SQUARE);
      beginShape();
      int vx = (steep) ? 0 : 1;
      int vy = (steep) ? 1 : 0;
      if (u < cx + 50) vx = -vx;
      if (v < cy) vy = -vy;
      vertex(u - vx * 8 - vy * 8, v - vx * 8 - vy * 8);
      vertex(u, v);
      vertex(u - vx * 8 + vy * 8, v -vy * 8 + vx * 8);
      endShape();
    }  
    if (linkDet) {
      var ex = document.getElementById("details").offsetLeft;
      var ew = document.getElementById("details").clientWidth;
      //if (abs(ex - detailsX) > 0) refresh = true; 
      stroke(col2);
      noFill();
      strokeWeight(2);
      beginShape();
      vertex(_x, _y);
      vertex(min(_x + r + 8 + 24, ex - 24), _y);
      vertex(ex - 24, detailsY);
      vertex(ex + ew - 2, detailsY);      
      endShape();
    }
    if (linkVir) { 
      stroke(col1);
      noFill();
      strokeWeight(2); 
      beginShape();
      vertex(_x, _y);
      vertex(172, 16);      
      endShape();
    }
    if (linkList) { 
      fill(col2);
      noStroke();
      ellipse(lx, ly, 8, 8);
      stroke(col1);
      noFill();
      strokeWeight(2); 
      beginShape();
      vertex(_x, _y);
      vertex(lx-12, _y);
      vertex(lx-12, ly);
      vertex(lx, ly);      
      endShape();
    }
  }
}

void selectProject(Project p) {
  var dets = document.getElementById("details");
  var vir = document.getElementById("virtual"); 
  dets.className = dets.className.replace("vis", "hid");
  
  if (selP == null) {
    selP = p;
    updateDetailsDiv();
    return;
  } else {
    selP.selected = false; 
    selP.linkDet = false;
    selP.linkVir = false;  
    if (p == selP) p = null;
    if (p == null) {
      zoomSel();
    }
  }  
  if (p != null) {
    selP = p;
    panTo(selP.x, selP.y);
    selP.selected = true;
    selP.linkDet = true;
    selP.linkVir = false;
    vir.className = vir.className.replace("vis", "hid");
    window.setTimeout(updateDetailsDiv, 500);
  } else {
    selP = null;
    vir.className = vir.className.replace("vis", "hid");
  }
  sLoop();
}

void updateDetailsDiv() {
//  float panY = (selP.y > w.h / 2) ? (selP.y) - (height / (4 * w.nz)) : (selP.y) + (height / (4 * w.nz));
  float panY = selP.y;
//  panTo((selP.x) + (width / (6 * w.nz)), panY);
  panTo((selP.x) + (width / (8 * w.nz)), panY);
//  panTo(selP.x,selP.y);
  selP.selected = true; 
  if (selP.details[10]) selP.linkVir = true;
  selP.linkDet = true;
  var d = document.getElementById("details");    
  d.className = "vis cat" + selP.cat;  

  d = document.getElementById("virtual");    
  d.className = (selP.details[10]) ? "vis cat" + selP.cat : "hid";
  d.href = (selP.details[10]) ? selP.details[10] : "#";

  d = document.getElementById("detailsheader");
  d.querySelector("#detailsname").innerHTML = selP.name;
  d.className = "cat" + selP.cat;
  
  d = document.getElementById("detailsp");
  d.innerHTML = (selP.details[0]) ? selP.details[0] : "No Description";

  d = document.getElementById("detailstable").getElementsByClassName("colB");
  for (int i = 0; i < 9; i++) {
    var tr = document.getElementById("dt" + i);
    tr.style.display = (selP.details[i+1]) ? "table-row" : "none";
    d[i].innerHTML = (selP.details[i+1]) ? selP.details[i+1] : "N/A";
  }

  //document.getElementById("details").style.height = "";
  //document.getElementById("detailsart").style.height = "";

  //var hmax = height * .9;
  var hh = document.getElementById("detailsheader").clientHeight;
  var ha = document.getElementById("detailsart").clientHeight;
/*
  //var dHeight = min(hmax, ha + hh + 40);
  var dHeight = 200;//ha + hh + 40;
 // var aHeight = dHeight - hh - 40;
 var aHeight = ha;//dHeight - hh -60;
 println(ha);
  document.getElementById("details").style.height = int(dHeight) + "px";
  document.getElementById("detailsart").style.height = int(aHeight) + "px";
    detailsY = (height - document.getElementById("details").clientHeight + hh) / 2.0;
*/
  document.getElementById("details").style.height = (ha + hh) + "px";
  detailsY = document.getElementById("details").offsetTop  + (hh / 2.0);

  window.setTimeout(updatescroll, 0);

  sLoop();
}

void linkToCat(var elem, var clear) { // set all lx's and ly's in setGUI in the beginning: in an array, xy per cat ID?
  if (elem != null) {
    int value = elem.previousElementSibling.value;
    var rect = localBoundingRect(elem);
    var y = (rect.top + rect.bottom) / 2;
    rect = localBoundingRect(document.getElementById("menu1"));
    var x = rect.right - rect.left + 12;
    for (Project p : projects) {
      if (clear) p.linkCat = false;
      for (int i = 0; i < 11; i++) {
        if (p.filter[i] == true && i == value) {
          p.linkCat = true;
          p.cx = x;
          p.cy = y;
        }
      }
    }
  } else if (clear) for (Project p : projects) p.linkCat = false;
} 

void linkToMe(var elem) { 
  if (elem != null) {
    var rect = localBoundingRect(elem);
    var y = (rect.top + rect.bottom) / 2;
    rect = localBoundingRect(document.getElementById("menu1"));
    var x = rect.right - rect.left + 12;
    for (Project p : projects) {
      p.linkCat = false;
      if (p.details[10]) {
          p.linkCat = true;
          p.cx = x;
          p.cy = y;
        }
      }
    } else for (Project p : projects) p.linkCat = false;
} 

void linkToList(var elem, var pid, var b) { 
  Project p = projects[pid]; 
  if (b) {   
    elem.className = "cat" + p.cat;
    var rec = localBoundingRect(elem);
    var y = (rec.top + rec.bottom) / 2;
    var x = rec.left;
    p.linkList = true;
    p.lx = x;
    p.ly = y;
  } else {
    p.linkList = false;
    elem.className = "";
  }
} 

void highlightV(boolean b) {
  for (Project p : projects) {
    if (p.details[10]) {
      if (b == true) p.selected = true;
      else if (p != selP) p.selected = false;
      p.draw();
    }
  } 
}

void toggleV(boolean b) {
  for (Project p : projects) {
    p.active = false;
    if (selO != null) if (!selO.containsPoint(p.x, p.y)) continue;
    if (p.details[10] || !b) p.active = true;
    if (!searchFilter[p.pid]) p.active = false;    
  } 
  clusterProjects();
  filterList();
  updatescroll2();
  window.setTimeout(updatescroll2, 250);
  sLoop();
}

void filterProjects() {
  for (Project p : projects) {
    p.active = false;
    if (selO != null) if (!selO.containsPoint(p.x, p.y)) continue;
    for (int i = 0; i < 11; i++) {
      if (masterFilter[i] && p.filter[i]) p.active = true;
    }
    if (!searchFilter[p.pid]) p.active = false;   
    if (VFilter && !p.details[10]) p.active = false; 
  } 
  clusterProjects();
  filterList();
  updatescroll2();
  window.setTimeout(updatescroll2, 250);
  sLoop();
}

void loadProjects() {
  try {
    String[] crude = loadStrings("data.json");
  } 
  catch (Exception E) {
    println("projects " + E);
    fakeProjects();
    return;
  }  
  var json = JSON.parse(crude);
  projects = new Project[json.length];
  for (int i = 0; i < json.length; i++) {
    var jp = json[i];
    Project p = new Project();
    p.name = jp.name;
    p.x = w.w * jp.x;
    p.y = w.h * jp.y; 
    p.N = jp.lat;
    p.E = jp.lng;
    p.z = jp.zoom;
    p.details[0] = jp.desc;
    p.details[1] = jp.client;
    p.details[2] = jp.scope;
    p.details[3] = jp.location;
    p.details[4] = jp.capacity;
    p.details[5] = jp.partner;
    p.details[6] = jp.tech;
    p.details[7] = jp.date;
    p.details[8] = jp.status;
    p.details[9] = jp.external;
    p.details[10] = jp.tour;
    p.filter = jp.filter;   
    
    for (int j = 0; j < 11; j++) {
      if (p.filter[j]) { 
        if (j < 5) p.cat = 0;
        else if (j < 7 && p.cat == -1) p.cat = 1;
        else if (j < 9 && p.cat == -1) p.cat = 2;
        else if (p.cat == -1) p.cat = 3;
      }
    }
    switch(p.cat) {
    case 0: 
      p.col1 = setAlpha(CAT0, 210);  
      p.col2 = CAT0;  
      break;
    case 1: 
      p.col1 = setAlpha(CAT1, 210);  
      p.col2 = CAT1;  
      break;      
    case 2: 
      p.col1 = setAlpha(CAT2, 210);  
      p.col2 = CAT2;  
      break;
    case 3: 
      p.col1 = setAlpha(CAT3, 210);  
      p.col2 = CAT3;  
      break;
    }     
    
    p.r = 12;
    p.pid = i;
    projects[i] = p;
  }
}

void fakeProjects() {
  projects = new Project[100];
  for (int i = 0; i < 100; i++) {
    Project p = new Project();
    p.name = "Errorling " + i;
    p.x = sq(random(1)) * w.w;
    p.y = sq(random(1)) * w.h; 
    p.N = null;
    p.E = null;

    for (int j = 0; j < 11; j++) {
      p.filter[j] = (random(j) > i/10.0) ? true : false;
    }
    for (int j = 0; j < 11; j++) {
      p.details[j] = "Errorling has no details";
    }    
    for (int j = 0; j < 11; j++) {
      if (p.filter[j]) { 
        if (j < 5) p.cat = 0;
        else if (j < 7 && p.cat == -1) p.cat = 1;
        else if (j < 9 && p.cat == -1) p.cat = 2;
        else if (p.cat == -1) p.cat = 3;
      }
    }
    switch(p.cat) {
    case 0: 
      p.col1 = setAlpha(CAT0, 210);  
      p.col2 = CAT0;  
      break;
    case 1: 
      p.col1 = setAlpha(CAT1, 210);  
      p.col2 = CAT1;  
      break;      
    case 2: 
      p.col1 = setAlpha(CAT2, 210);  
      p.col2 = CAT2;  
      break;
    case 3: 
      p.col1 = setAlpha(CAT3, 210);  
      p.col2 = CAT3;  
      break;
    } 
    p.r = 12;
    p.pid = i;
    projects[i] = p;
  }
}

Project[] getProjects() {
  return projects;
}

class World {
  float x, y, z, px, py, pz, nx, ny, nz, w, h;
  boolean newZ;
  BBox bb;

  World() {
    x = px = nx = 0.0f;
    y = py = ny = 0.0f;
    z = pz = nz = 1.0f;
    w = 1.0f;
    h = 1.0f;
    newZ = false;
    bb = new BBox();
  }

  float s2wX(float _x) {
    return _x / z - x;
  }

  float s2wY(float _y) {
    return _y / z - y;
  }
  float w2sX(float _x) {
    return (x + _x) * z ;
  }

  float w2sY(float _y) {
    return (y + _y) * z ;
  }

  void updateLinear() {
    if (z != nz) { 
      float z0 = z;    
      float d = nz-pz;
      d = abs(d)/d;
      z *= 1 + d * .05;
      if ((pz < nz && z > nz) || (pz > nz && z < nz)) z = nz;
      float x0 = (nx * (nz/z0) - x) / ((nz/z0) - 1);
      float y0 = (ny * (nz/z0) - y) / ((nz/z0) - 1);
      x = x0 + (x - x0) / (z/z0);
      y = y0 + (y - y0) / (z/z0);
      refresh = true;
    } else {
      if (abs (nx - x) * z > .5) { 
        x = lerp(x, nx, .1); 
        refresh = true;
      }
      if (abs (ny - y) * z > .5) { 
        y = lerp(y, ny, .1); 
        refresh = true;
      } 
    }
    if (refresh) updateBB();
  }

  void update() {
    if (nz / z > 1.001 || nz / z < .999) { 
      float z0 = z;   
      float r = 1 - ((nz-z)/(nz-pz));    
      z = lerp(z, nz, max(r*.2,.01));       
      float x0 = (nx * (nz/z0) - x) / ((nz/z0) - 1);
      float y0 = (ny * (nz/z0) - y) / ((nz/z0) - 1);
      x = x0 + (x - x0) / (z/z0);
      y = y0 + (y - y0) / (z/z0);
      refresh = true;
    } else {
      if (abs (nx - x) * z > .5) { 
        x = lerp(x, nx, .1); 
        refresh = true;
      }
      if (abs (ny - y) * z > .5) { 
        y = lerp(y, ny, .1); 
        refresh = true;
      } 
    }
    if (refresh) updateBB();
  }

  void updateBB() {
    bb.x = -x; 
    bb.y = -y; 
    bb.w = width/z; 
    bb.h = height/z;
  }
  void hold() {
    px = x;
    py = y;
    pz = z;
    newZ = true;
  }
}

void zoom(float x, float y, float z) {
  w.hold();
  if (w.nz <= 1 && z <= 1) { x = width/2; y = height/2;}
  x = constrain(x, w.w2sX(0), w.w2sX(w.w));
  y = constrain(y, w.w2sY(0), w.w2sY(w.h));
  w.nx = w.nx - x / w.nz + x / z;
  w.ny = w.ny - y / w.nz + y / z;  
  w.nz = z;
}

void zoomIn() {
  zoom(width/2, height/2, w.nz * 2);
}

void zoomOut() {
  zoom(width/2, height/2, w.nz * .5);
}

void zoomWin(float x, float y, float nw, float nh) {
  w.hold();
  w.nz = .8 * min(width / nw, height / nh);  
  w.nz = constrain(w.nz, 1, 8); 
  w.nx = -x + (width - nw*w.nz) / (2 * w.nz);
  w.ny = -y + (height - nh*w.nz) / (2 * w.nz);
}  

void zoomWinFree(float x, float y, float nw, float nh) {
  w.hold();
  w.nz = .5 * min(width / nw, height / nh);  
  w.nx = -x + (width - nw*w.nz) / (2 * w.nz);
  w.ny = -y + (height - nh*w.nz) / (2 * w.nz);
  newZ = true;
}  
void zoomExt() {
  w.hold();
  w.nz = 1;
  w.nx = -w.w/2 + width/2;
  w.ny = -w.h/2 + height/2;
}  

void zoomSel() {
  if (selP != null) if (w.z > 2) panTo(selP.x, selP.y);
  else if (selO == null) zoomExt();
  else zoomWin(selO.bb.x, selO.bb.y, selO.bb.w, selO.bb.h);
}

void panTo(float x, float y) {
  w.nx = -x + (width) / (2 * w.nz);
  w.ny = -y + (height) / (2 * w.nz); 
}

float distsq( float x1, float y1, float x2, float y2) {
  float d = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
  return d;
}

float distch( float x1, float y1, float x2, float y2) {
  float d = max(abs(x2 - x1), abs(y2 - y1));
  return d;
}

float ease(float value, float target, float easingVal) {
  float d = target - value;
  if (abs(d)>1) {
    value+= d*easingVal;
    refresh = true;
  } else {
    value = target;
  }
  return value;
}

int animate(int value, int target, int step) {
  if (abs(target - value) < step) return target;  
  if (value < target) { 
    value += step; 
    value = min(value, target);        
    refresh = true;
  } else if (value > target) {
    value -= step; 
    value = max(value, target);        
    refresh = true;
  } 
  return value;
}  

float animate(float value, float target, float step) {
  if (abs(target - value) < step) return target;
  if (value < target) { 
    value += step; 
    value = min(value, target);        
    refresh = true;
  } else if (value > target) {
    value -= step; 
    value = max(value, target);        
    refresh = true;
  } 
  return value;
}  


