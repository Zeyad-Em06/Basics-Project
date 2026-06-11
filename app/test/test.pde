boolean shotIsFiring = false;
int firingTimer = 0;
boolean[] shipTargets = new boolean[5]; 
int playerAssignedShip = 0;             
boolean gameOver = false;               

// Animation variable for the floaty wave oscillation loop
float floatAngle = 0;

void setup() {
  size(800, 500);
  pixelDensity(1); // Force crisp blocky pixel alignment
  frameRate(60);
  resetGame();
}

void draw() {
  // 1. LIGHTENED CARTOON SKY BACKGROUND
  background(100, 200, 255); // Friendly, bright sky blue for children
  
  // Update wave animation angle increment
  floatAngle += 0.05;
  
  // 2. RETRO SCENERY (Drawn deep in the backdrop layer)
  drawPixelSun(80, 52);
  
  // Decorative tropical background island palm trees
  drawPixelPalmTree(140, 115, 2.5);
  drawPixelPalmTree(750, 95, 3.0);
  drawPixelPalmTree(262, 95, 1.8);
  
  // 3. CENTERED PIXEL TITLE
  drawPixelTitle();
  
  // 4. DASHBOARD PANELS
  // Shot Status Box
  if (shotIsFiring) {
    drawPixelPanel(40, 120, 220, 90, color(255, 0, 68), color(120, 10, 40));
    drawPixelText("SHOT FIRED!", 65, 155, 2, color(255, 255, 255));
    firingTimer++;
    if (firingTimer > 12) {
      shotIsFiring = false;
      firingTimer = 0;
    }
  } else {
    drawPixelPanel(40, 120, 220, 90, color(0, 180, 255), color(20, 50, 90));
    drawPixelText("WAITING...", 85, 155, 2, color(0, 255, 221));
  }
  
  // Friend Ship Assign Box
  drawPixelPanel(40, 230, 220, 90, color(255, 0, 180), color(90, 15, 65));
  drawPixelText("YOUR FRIEND:", 65, 245, 1.5, color(255, 180, 220));
  drawPixelText("SHIP " + playerAssignedShip, 80, 272, 2.5, color(255, 230, 0));

  // 5. BRIGHT TROPICAL PIXEL OCEAN LAYERS
  drawLayeredPixelOcean(280, 100, 500, 310);

  // 6. TWO-ROW TACTICAL FLEET GRID (Pixel Art Ships)
  for (int i = 0; i < 5; i++) {
    int currentShipNumber = i + 1;
    boolean isPlayerShip = (currentShipNumber == playerAssignedShip);
    
    float xPos, yPos;
    if (i < 2) {
      xPos = 425 + (i * 210);
      yPos = 135;
    } else {
      xPos = 350 + ((i - 2) * 180);
      yPos = 290; 
    }
    
    if (shipTargets[i]) {
      // SUNK STATE: Rigid decoupled falling calculations beneath the bright sea
      draw8BitShip(xPos, yPos, true, isPlayerShip); 
      drawPixelText("SUNK!", (int)xPos - 22, (int)yPos + 65, 1.5, color(255, 40, 40)); 
    } else {
      // INTACT STATE: Smooth floaty tracking
      float currentFloatOffset = sin(floatAngle + i) * 5.0;
      draw8BitShip(xPos, yPos + currentFloatOffset, false, isPlayerShip);
      
      if (isPlayerShip) {
        drawPixelText("DONT SHOOT!", (int)xPos - 45, (int)yPos + 65, 1.5, color(255, 230, 0)); 
      } else {
        drawPixelText("SHIP " + currentShipNumber, (int)xPos - 25, (int)yPos + 65, 1.5, color(255, 255, 255));
      }
    }
  }
  
  // 7. RETRO GAME OVER OVERLAY
  if (gameOver) {
    fill(20, 15, 35, 240);
    rect(280, 110, 490, 290);
    stroke(255, 0, 68);
    strokeWeight(4);
    noFill();
    rect(285, 115, 480, 280);
    
    drawPixelText("GAME OVER!", 405, 195, 3.5, color(255, 0, 68));
    drawPixelText("YOU HIT YOUR FRIEND SHIP", 345, 255, 1.5, color(255, 255, 255));
    drawPixelText("PRESS RESET TO TRY AGAIN", 345, 285, 1.5, color(0, 255, 240));
  }
  
  // 8. CARTOON ARCADE BUTTONS
  if (!gameOver) {
    drawArcadeButton(40, 415, 220, 45, color(0, 230, 100), color(0, 130, 50), "TEST SHOOT");
  } else {
    drawArcadeButton(40, 415, 220, 45, color(100, 105, 115), color(60, 65, 70), "TEST SHOOT");
  }
  
  drawArcadeButton(300, 415, 220, 45, color(255, 130, 0), color(170, 70, 0), "RESET GAME");
}

// Custom Render: Draws authentic pixel text line using hardcoded character matrices
void drawPixelText(String txt, int x, int y, float pixelScale, color c) {
  pushMatrix();
  translate(x, y);
  fill(c);
  noStroke();
  
  for (int i = 0; i < txt.length(); i++) {
    char ch = txt.charAt(i);
    int[][] glyph = getPixelGlyph(ch);
    
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (glyph[row][col] == 1) {
          rect(col * pixelScale, row * pixelScale, pixelScale, pixelScale);
        }
      }
    }
    translate(6 * pixelScale, 0); 
  }
  popMatrix();
}

// Custom Render: Decorative double-bordered UI layout panel
void drawPixelPanel(int x, int y, int w, int h, color border, color bg) {
  fill(0);
  stroke(0);
  strokeWeight(6);
  rect(x, y, w, h); 
  
  fill(bg);
  stroke(border);
  strokeWeight(3);
  rect(x+2, y+2, w-4, h-4); 
}

// Custom Render: High-contrast 3D arcade styling buttons
void drawArcadeButton(int x, int y, int w, int h, color face, color shadow, String label) {
  fill(0);
  rect(x, y, w, h + 5, 4); 
  
  fill(shadow);
  rect(x, y + 4, w, h, 4); 
  
  fill(face);
  stroke(255, 255, 255, 80);
  strokeWeight(1.5);
  rect(x, y, w, h, 4);     
  
  int labelX = x + (w / 2) - (int)((label.length() * 6 * 1.5) / 2);
  int labelY = y + (h / 2) - 4;
  drawPixelText(label, labelX, labelY, 1.5, color(255));
}

// Custom Render: Title layout engine with isolated letters parameters (Pink line removed)
void drawPixelTitle() {
  int startX = width / 2 - 200;
  color titleColor = color(255, 255, 0); // Bright arcade yellow for kids
  color shadowColor = color(20, 20, 40); // Deep contrast drop shadow
  
  // --- WORD 1: PIRATES ---
  drawPixelText("PIRATES", startX + 2, 42, 3.5, shadowColor);
  drawPixelText("PIRATES", startX, 40, 3.5, titleColor);
  
  // --- WORD 2: LAGOON ---
  drawPixelText("L", startX + 197, 42, 3.5, shadowColor);
  drawPixelText("L", startX + 195, 40, 3.5, titleColor);
  drawPixelText("A", startX + 222, 42, 3.5, shadowColor);
  drawPixelText("A", startX + 220, 40, 3.5, titleColor);
  drawPixelText("G", startX + 247, 42, 3.5, shadowColor);
  drawPixelText("G", startX + 245, 40, 3.5, titleColor);
  
  // Dropped wheels down to y=40 to horizontally line up with text baselines
  drawPixelWheel(startX + 282, 40);
  drawPixelWheel(startX + 316, 40);
  
  drawPixelText("N", startX + 347, 42, 3.5, shadowColor);
  drawPixelText("N", startX + 345, 40, 3.5, titleColor);
}

// Custom Render: Detailed pixelated 8-spoke steering wheel
void drawPixelWheel(int x, int y) {
  pushMatrix();
  translate(x, y);
  
  // Wheel Drop Shadow
  fill(20, 20, 40);
  noStroke();
  float p = 2.5;
  rect(2*p+1, 1, 3*p, p); rect(1, 2*p+1, p, 3*p); rect(6*p+1, 2*p+1, p, 3*p); rect(2*p+1, 6*p+1, 3*p, p);
  
  // Wheel Face
  fill(255, 150, 0);
  rect(2*p, 0, 3*p, p); rect(0, 2*p, p, 3*p); rect(6*p, 2*p, p, 3*p); rect(2*p, 6*p, 3*p, p);
  rect(3*p, 3*p, p, p); 
  rect(3*p, -1*p, p, p); rect(3*p, 7*p, p, p); rect(-1*p, 3*p, p, p); rect(7*p, 3*p, p, p);
  rect(1*p, 1*p, p, p); rect(5*p, 1*p, p, p); rect(1*p, 5*p, p, p); rect(5*p, 5*p, p, p);
  popMatrix();
}

// Custom Render: Renders a beautifully defined 8-bit retro sun
void drawPixelSun(int x, int y) {
  pushMatrix();
  translate(x, y);
  noStroke();
  float p = 3.5; 
  
  // Outer Radiant Orange Layer
  fill(255, 110, 0);
  rect(-6*p, -13*p, 13*p, 27*p);
  rect(-13*p, -6*p, 27*p, 13*p);
  rect(-10*p, -10*p, 21*p, 21*p);
  
  // Inner Core Bright Yellow
  fill(255, 230, 0);
  rect(-4*p, -11*p, 9*p, 23*p);
  rect(-11*p, -4*p, 23*p, 9*p);
  rect(-8*p, -8*p, 17*p, 17*p);
  
  popMatrix();
}

// Custom Render: Renders a retro blocky 8-bit palm tree asset signature with island sand base
void drawPixelPalmTree(int x, int y, float p) {
  pushMatrix();
  translate(x, y);
  noStroke();
  
  color sandYellow = color(235, 200, 100);
  color trunkBrown = color(140, 75, 20);
  color leafGreen  = color(0, 180, 60);
  color darkLeaf   = color(0, 120, 30);
  
  // 1. Semi-Circular Sandy Island Mound Base Floor
  fill(sandYellow);
  rect(-6*p, 0, 14*p, 4*p);
  rect(-10*p, 2*p, 22*p, 2*p);
  
  // 2. Notched Curved Trunk Matrix
  fill(trunkBrown);
  rect(0, 0, 2*p, -4*p);
  rect(0.5*p, -4*p, 2*p, -4*p);
  rect(1.5*p, -8*p, 2*p, -4*p);
  rect(2.8*p, -12*p, 2*p, -4*p);
  rect(4.5*p, -16*p, 2*p, -3*p);
  
  // 3. Overhanging Leaf Clusters
  translate(5.5*p, -17*p);
  fill(darkLeaf);
  rect(-6*p, -2*p, 4*p, 2*p);
  rect(3*p, -2*p, 4*p, 2*p);
  
  fill(leafGreen);
  rect(-4*p, -4*p, 9*p, 2*p);
  rect(-1*p, -6*p, 3*p, 2*p);
  rect(-7*p, 0, 3*p, p);
  rect(5*p, 0, 3*p, p);
  
  popMatrix();
}

// Custom Render: Bright, flooded tropical retro ocean box environment
void drawLayeredPixelOcean(int x, int y, int w, int h) {
  noStroke();
  
  color deepAbyss = color(10, 45, 110);   
  color midWater  = color(0, 110, 210);  
  color surfCyan  = color(0, 210, 255);  
  
  // Flood background deep sea container base across target coordinate zone
  fill(deepAbyss);
  rect(x, y, w, h, 8);
  
  // Row 1 Water Block
  fill(midWater);
  rect(x + 4, y + 42, w - 8, 32);
  fill(surfCyan);
  rect(x + 4, y + 42, w - 8, 6); 
  
  // Row 2 Water Block
  fill(midWater);
  rect(x + 4, y + 197, w - 8, 32);
  fill(surfCyan);
  rect(x + 4, y + 197, w - 8, 6); 
}

// Advanced 8-Bit Ship Engine: Splitting hull physics with frame-animated smoke/fire particles
void draw8BitShip(float x, float y, boolean isDestroyed, boolean isPlayerShip) {
  pushMatrix();
  translate(x, y);
  noStroke();
  
  float p = 4.0; 
  
  color woodSkin  = color(165, 85, 30);
  color woodTrim  = color(100, 45, 15);
  color gunMetal  = color(50, 55, 65);
  color neonGold  = color(255, 200, 0);
  color maskBlack = color(25, 25, 30);
  color boneWhite = color(255, 255, 255);

  if (isDestroyed) {
    // Left Hull Half
    pushMatrix();
    translate(-16, 26); 
    rotate(radians(-40));
    fill(woodSkin);
    rect(-6*p, 0, 6*p, 3*p);
    fill(woodTrim);
    rect(-7*p, -p, 7*p, p);
    popMatrix();

    // Right Hull Half
    pushMatrix();
    translate(18, 18); 
    rotate(radians(48));
    fill(woodTrim);
    rect(-0.5*p, -4*p, p, 5*p); 
    fill(woodSkin);
    rect(0, 0, 6*p, 3*p);
    fill(woodTrim);
    rect(0, -p, 7*p, p);
    popMatrix();
    
    // Smoke/Fire Systems
    int frameCheck = frameCount % 30;
    if (frameCheck < 15) {
      fill(255, 50, 0); 
      rect(-2*p, -1*p, 2*p, 2*p);
      rect(1*p, -3*p, p, p);
      fill(255, 230, 0); 
      rect(-1*p, -1*p, p, p);
    } else {
      fill(255, 150, 0); 
      rect(-1*p, -2*p, 3*p, 1.5*p);
      rect(-3*p, 0, p, p);
      fill(255, 255, 255); 
      rect(0, -1*p, p, p);
    }
    
    fill(60, 65, 75, 200); 
    rect(-4*p, -4*p - (frameCheck/3.0), 2*p, 2*p);
    rect(2*p, -7*p - (frameCheck/4.0), 3*p, 2*p);
    rect(0, -10*p - (frameCheck/5.0), 2*p, 2*p);
    
  } else {
    // 1. Center Mast Timber
    fill(woodTrim);
    rect(-0.5*p, -10*p, p, 11*p);
    
    // 2. Curvature Sail Profiles
    if (isPlayerShip) {
      fill(boneWhite); 
    } else {
      fill(maskBlack); 
    }
    rect(-4*p, -9*p, 8*p, p);
    rect(-5*p, -8*p, 10*p, p);
    rect(-5*p, -7*p, 11*p, p);
    rect(-5*p, -6*p, 11*p, p);
    rect(-5*p, -5*p, 10*p, p);
    rect(-4*p, -4*p, 9*p, p);
    rect(-3*p, -3*p, 7*p, p);
    rect(-2*p, -2*p, 5*p, p);
    
    // 3. Pirate Skull Grid Insignia
    if (!isPlayerShip) {
      fill(boneWhite);
      rect(-2*p, -7*p, 4*p, 3*p); 
      rect(-1*p, -4*p, 2*p, p);   
      fill(maskBlack);
      rect(-1.5*p, -6*p, p, p); rect(0.5*p, -6*p, p, p);
    }
    
    // 4. Layered Wooden Boat Hull
    fill(woodSkin);
    rect(-7*p, 1*p, 14*p, p);   
    rect(-6*p, 2*p, 12*p, p);   
    rect(-5*p, 3*p, 10*p, p);   
    fill(woodTrim);
    rect(-4*p, 4*p, 8*p, p);    
    
    // 5. Cannon Ports Shading
    fill(gunMetal);
    rect(-4*p, 2*p, p, p); rect(-0.5*p, 2*p, p, p); rect(3*p, 2*p, p, p);
    fill(neonGold);
    rect(-4*p, 3*p, p, 0.5*p); rect(-0.5*p, 3*p, p, 0.5*p); rect(3*p, 3*p, p, 0.5*p);
  }
  popMatrix();
}

void resetGame() {
  gameOver = false;
  shotIsFiring = false;
  firingTimer = 0;
  playerAssignedShip = int(random(1, 6)); 
  
  for (int i = 0; i < 5; i++) {
    shipTargets[i] = false;
  }
}

void mousePressed() {
  if (!gameOver && mouseX >= 40 && mouseX <= 260 && mouseY >= 415 && mouseY <= 460) {
    shotIsFiring = true;
    firingTimer = 0;
  }
  
  if (mouseX >= 300 && mouseX <= 520 && mouseY >= 415 && mouseY <= 460) {
    resetGame();
  }
  
  if (!gameOver) {
    for (int i = 0; i < 5; i++) {
      float xPos, yPos;
      if (i < 2) {
        xPos = 425 + (i * 210);
        yPos = 135;
      } else {
        xPos = 350 + ((i - 2) * 180);
        yPos = 290; 
      }
      
      if (mouseX >= xPos - 40 && mouseX <= xPos + 40 && mouseY >= yPos - 45 && mouseY <= yPos + 35) {
        shipTargets[i] = true; 
        if ((i + 1) == playerAssignedShip) {
          gameOver = true;
        }
      }
    }
  }
}

// Low-Level Library Font Mapping Matrix
int[][] getPixelGlyph(char c) {
  int[][] g = new int[5][5];
  switch(Character.toUpperCase(c)) {
    case 'P': return new int[][]{{1,1,1,1,0},{1,0,0,0,1},{1,1,1,1,0},{1,0,0,0,0},{1,0,0,0,0}};
    case 'I': return new int[][]{{0,1,1,1,0},{0,0,1,0,0},{0,0,1,0,0},{0,0,1,0,0},{0,1,1,1,0}};
    case 'R': return new int[][]{{1,1,1,1,0},{1,0,0,0,1},{1,1,1,1,0},{1,0,0,1,0},{1,0,0,0,1}};
    case 'A': return new int[][]{{0,1,1,1,0},{1,0,0,0,1},{1,1,1,1,1},{1,0,0,0,1},{1,0,0,0,1}};
    case 'T': return new int[][]{{1,1,1,1,1},{0,0,1,0,0},{0,0,1,0,0},{0,0,1,0,0},{0,0,1,0,0}};
    case 'E': return new int[][]{{1,1,1,1,1},{1,0,0,0,0},{1,1,1,1,0},{1,0,0,0,0},{1,1,1,1,1}};
    case 'S': return new int[][]{{0,1,1,1,1},{1,0,0,0,0},{0,1,1,1,0},{0,0,0,0,1},{1,1,1,1,0}};
    case 'L': return new int[][]{{1,0,0,0,0},{1,0,0,0,0},{1,0,0,0,0},{1,0,0,0,0},{1,1,1,1,1}};
    case 'G': return new int[][]{{0,1,1,1,1},{1,0,0,0,0},{1,0,1,1,1},{1,0,0,0,1},{0,1,1,1,0}};
    case 'N': return new int[][]{{1,0,0,0,1},{1,1,0,0,1},{1,0,1,0,1},{1,0,0,1,1},{1,0,0,0,1}};
    case 'W': return new int[][]{{1,0,0,0,1},{1,0,0,0,1},{1,0,1,0,1},{1,1,0,1,1},{1,0,0,0,1}};
    case 'O': return new int[][]{{0,1,1,1,0},{1,0,0,0,1},{1,0,0,0,1},{1,0,0,0,1},{0,1,1,1,0}};
    case 'H': return new int[][]{{1,0,0,0,1},{1,0,0,0,1},{1,1,1,1,1},{1,0,0,0,1},{1,0,0,0,1}};
    case 'U': return new int[][]{{1,0,0,0,1},{1,0,0,0,1},{1,0,0,0,1},{1,0,0,0,1},{0,1,1,1,0}};
    case 'M': return new int[][]{{1,0,0,0,1},{1,1,0,1,1},{1,0,1,0,1},{1,0,0,0,1},{1,0,0,0,1}};
    case 'V': return new int[][]{{1,0,0,0,1},{1,0,0,0,1},{1,0,0,0,1},{0,1,0,1,0},{0,0,1,0,0}};
    case 'Y': return new int[][]{{1,0,0,0,1},{0,1,0,1,0},{0,0,1,0,0},{0,0,1,0,0},{0,0,1,0,0}};
    case 'D': return new int[][]{{1,1,1,1,0},{1,0,0,0,1},{1,0,0,0,1},{1,0,0,0,1},{1,1,1,1,0}};
    case 'K': return new int[][]{{1,0,0,0,1},{1,0,0,1,0},{1,1,1,0,0},{1,0,0,1,0},{1,0,0,0,1}};
    case 'F': return new int[][]{{1,1,1,1,1},{1,0,0,0,0},{1,1,1,1,0},{1,0,0,0,0},{1,0,0,0,0}};
    case '1': return new int[][]{{0,0,1,0,0},{0,1,1,0,0},{0,0,1,0,0},{0,0,1,0,0},{0,1,1,1,0}};
    case '2': return new int[][]{{0,1,1,1,0},{1,0,0,0,1},{0,0,0,1,0},{0,0,1,0,0},{1,1,1,1,1}};
    case '3': return new int[][]{{1,1,1,1,0},{0,0,0,0,1},{0,1,1,1,0},{0,0,0,0,1},{1,1,1,1,0}};
    case '4': return new int[][]{{1,0,0,1,0},{1,0,0,1,0},{1,1,1,1,1},{0,0,0,1,0},{0,0,0,1,0}};
    case '5': return new int[][]{{1,1,1,1,1},{1,0,0,0,0},{1,1,1,1,0},{0,0,0,0,1},{1,1,1,1,0}};
    case ':': return new int[][]{{0,0,0,0,0},{0,0,1,0,0},{0,0,0,0,0},{0,0,1,0,0},{0,0,0,0,0}};
    case '.': return new int[][]{{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,1,0,0}};
    case '!': return new int[][]{{0,0,1,0,0},{0,0,1,0,0},{0,0,1,0,0},{0,0,0,0,0},{0,0,1,0,0}};
  }
  return g; 
}
