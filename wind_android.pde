import ketai.camera.*;
import ketai.sensors.*;
import blobDetection.*;

KetaiCamera cam;

public int camW = 640;
public int camH = 480;
int tot;

color[] res;
PImage im;
boolean newFrame;
PVector wind;

PGraphics pg;

float noiseIncrement = 0.1;
float noiseCursor = 0;

boolean showStatus = false;
double longitude, latitude, altitude;
KetaiLocation location;

boolean stereo = true;

BlobDetection theBlobDetection;

void setup() {
  orientation(LANDSCAPE);
  cam = new KetaiCamera(this, camW, camH, 24); 
  res = new color[camW * camH];
  for (int i = 0; i < camW * camH; i++) res[i] = color(random(255));
  im = createImage (camW, camH, RGB);
  im.loadPixels();
  arrayCopy (res, im.pixels);
  im.updatePixels();
  tot = camW * camH;

  theBlobDetection = new BlobDetection(camW, camH);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(0.2f); 
  newFrame = false;

  wind = new PVector(0, 0);

  pg = createGraphics(camW, camH);
  pg.textSize(12);
  pg.stroke (255, 0, 0);
  pg.strokeWeight (3);
  tint (255, 255, 255, 255);
  fill(255, 255, 255, 255);

  location = new KetaiLocation(this);
}


void draw() {
  background(0);

  noiseCursor += noiseIncrement;

  pg.beginDraw();
  pg.background(0, 0, 0);

  if (!cam.isStarted()) {
    cam.start();
  } 

  float dx; //  = pmouseX - mouseX;
  float dy; //  = pmouseY - mouseY;

  float windMax = 10;

  // dx = windMax/2 - random(windMax);
  // dy = windMax/2 - random(windMax);

  dx = noise(noiseCursor) - 0.5 * windMax;
  dy = noise(noiseCursor + 100) - 0.5 * windMax;


  //pg.line (width/2+dx, height/2+dy, width/2, height/2);

  wind.x = dx;
  wind.y = dy;
  float step = 1;

  if (wind.mag() == 0) {

    pg.tint (255, 255, 255, 255);
    pg.image(im, 0, 0, width, height); // no wind
  } else {

    float alpha = 1 / wind.mag() * step;
    pg.tint (255, 255, 255, 255 * alpha);

    for (int i = 0; i < wind.mag (); i+=step) {
      pg.image(im, dx*i, dy*i, camW, camH);
    }
  }

  pg.text ("wind(x): " + dx, 10, 10);
  pg.text ("wind(y): " + dy, 10, 20);


  if (location.getProvider() == "none") {
    pg.text("Location data is unavailable, check the location settings.", 10, 30);
  }
  else {
    pg.text("Latitude: " + latitude + " " + 
      "Longitude: " + longitude + " " + 
      "Altitude: " + altitude + " " + 
      "Provider: " + location.getProvider(), 10, 30);
  }

  if (showStatus) {
    pg.text ("framerate: " + frameRate, 10, 40);
  }

  pg.endDraw();


  image(pg, 0, 0, width, height);
}


void onLocationEvent(double _latitude, double _longitude, double _altitude){
  longitude = _longitude;
  latitude = _latitude;
  altitude = _altitude;
  println("lat/lon/alt: " + latitude + "/" + longitude + "/" + altitude);
}

void onCameraPreviewEvent() {
  cam.read();  
  im = cam.get();
}

void mousePressed() {
  showStatus = !showStatus;
  /*
  if (cam.isFlashEnabled())
   cam.disableFlash();
   else
   cam.enableFlash();
   */
}


// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
void fastblur(PImage img, int radius) {
  if (radius<1) {
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0; i<256*div; i++) {
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0; y<h; y++) {
    rsum=gsum=bsum=0;
    for (i=-radius; i<=radius; i++) {
      p=pix[yi+min(wm, max(i, 0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0; x<w; x++) {

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if (y==0) {
        vmin[x]=min(x+radius+1, wm);
        vmax[x]=max(x-radius, 0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0; x<w; x++) {
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for (i=-radius; i<=radius; i++) {
      yi=max(0, yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0; y<h; y++) {
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if (x==0) {
        vmin[y]=min(y+radius+1, hm)*w;
        vmax[y]=max(y-radius, 0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
}

void appplyWind(float x, float y) {
}

void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges) {
  noFill();
  Blob b;
  EdgeVertex eA, eB;

  for (int n = 0; n < theBlobDetection.getBlobNb (); n++) {
    b = theBlobDetection.getBlob(n);
    if (b != null) {
      // Edges
      if (drawEdges) {
        strokeWeight(3);
        stroke(0, 255, 0);
        for (int m = 0; m < b.getEdgeNb (); m++) {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null) {
            line(
              eA.x*width, eA.y*height, 
              eB.x*width, eB.y*height
              );
          }
        }
      }

      // Blobs
      if (drawBlobs) {
        strokeWeight(1);
        stroke(255, 0, 0);
        rect(
          b.xMin*width, b.yMin*height, 
          b.w*width, b.h*height
          );
      }
    }
  }
}