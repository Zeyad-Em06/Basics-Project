#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <DFRobotDFPlayerMini.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
SoftwareSerial dfSerial(11, 9); // RX=D11, TX=D9
DFRobotDFPlayerMini dfPlayer;

#define SHOOT_BUTTON 4

const char* playerNames[] = {"SHOKRY", "ZEYAD", "MOAZ", "YASSIN", "ADHAM"};
int trackBase[]           = {1, 8, 15, 22, 29};
int workingPlayers[]      = {0, 1, 2, 3}; // ADHAM removed from active track logic

// Simple state tracking flags (No enum state machines)
bool isGameActive    = false;
bool isGameWon       = false;
bool isGameLost      = false;

int allyIndex        = -1;
bool targetsHit[5]   = {false, false, false, false, false};
int targetsHitCount  = 0;
int totalScore       = 0;
bool waitingForHit   = false;
bool ballIsBig       = true;
unsigned long endScreenTime = 0;

void playTrack(int trackNum) {
  dfSerial.listen();
  dfPlayer.playMp3Folder(trackNum);
}

void updateLCD() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Ally:");
  lcd.print(playerNames[allyIndex]);
  lcd.setCursor(0, 1);
  lcd.print("Sc:");
  lcd.print(totalScore);
  lcd.print(" ");
  lcd.print(targetsHitCount);
  lcd.print("/4 ");
  lcd.print(ballIsBig ? "[BIG]" : "[SML]");
}

void initGame() {
  for (int i = 0; i < 5; i++) targetsHit[i] = false;
  targetsHitCount = 0;
  totalScore      = 0;
  waitingForHit   = false;
  ballIsBig       = true;
  isGameActive    = true;
  isGameWon       = false;
  isGameLost      = false;

  // Single-byte Reset token to Worker
  Serial.write('R');
  Serial.flush();
  while (Serial.available()) Serial.read();

  randomSeed(analogRead(A0));
  allyIndex = random(0, 5);

  // Sync token sequence to Processing.io over Bluetooth
  Serial.print('I'); 
  Serial.print(allyIndex + 1); // Processing expects 1-5 format
  Serial.print('\n');
  Serial.flush();

  playTrack(trackBase[allyIndex]);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Ally:");
  lcd.print(playerNames[allyIndex]);
  lcd.setCursor(0, 1);
  lcd.print("Sc:0  0/4 [BIG]");
}

void setup() {
  pinMode(SHOOT_BUTTON, INPUT_PULLUP);

  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("Starting...");

  delay(2000);
  dfSerial.begin(9600);
  delay(1000);

  dfPlayer.begin(dfSerial);
  delay(500);
  dfPlayer.volume(25);
  dfPlayer.EQ(DFPLAYER_EQ_NORMAL);

  lcd.clear();
  lcd.print("DFPlayer Ready");
  delay(1000);

  Serial.begin(9600); // Bluetooth Link & Worker Shared Bus
  delay(500);
  while (Serial.available()) Serial.read();

  initGame();
}

void loop() {
  // Post-game auto-restart delay tracking loop
  if (!isGameActive && (millis() - endScreenTime >= 5000)) {
    initGame();
    return;
  }

  // Handle playing state updates
  if (isGameActive) {
    // Firing Request Handler
    if (digitalRead(SHOOT_BUTTON) == LOW && !waitingForHit) {
      Serial.write('F'); // Single-byte Fire token down hard wire to Worker
      Serial.flush();
      waitingForHit = true;

      // Pass token out to sync the Processing screen animation update
      Serial.print("FIRE\n");
      Serial.flush();

      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("  ** FIRE! ** ");
      lcd.setCursor(0, 1);
      lcd.print(ballIsBig ? "Ball:BIG  +1pt" : "Ball:SML  +2pt");

      while (digitalRead(SHOOT_BUTTON) == LOW);
      delay(200); // Simple mechanical button debounce window
    }

    // Inbound evaluation parsing from Worker via RX line
    if (Serial.available() && waitingForHit) {
      char hit = Serial.read();
      int irIndex = hit - '1'; // Converts '1'-'5' array bounds back to 0-4

      if (irIndex >= 0 && irIndex <= 4) {
        waitingForHit = false;

        bool thisBallBig = ballIsBig;
        ballIsBig = !ballIsBig;

        // Loss Condition Check: Friend Target Tripped
        if (irIndex == allyIndex) {
          isGameActive = false;
          isGameLost = true;
          
          playTrack(trackBase[allyIndex] + 5); // Play lose track
          
          Serial.print("LOSE\n"); // Notify Processing over Bluetooth
          Serial.flush();
          
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print(" ** GAME OVER **");
          lcd.setCursor(0, 1);
          lcd.print("Hit Friend Ship!");
          endScreenTime = millis();
          return;
        }

        // Score Calculation & Hit Registry Updates
        if (!targetsHit[irIndex]) {
          targetsHit[irIndex] = true;
          targetsHitCount++;

          int points = thisBallBig ? 1 : 2;
          totalScore += points;

          // Notify Processing over Bluetooth to sink this specific ship item
          Serial.print('H');
          Serial.print(irIndex + 1); // Match 1-5 alignment metrics
          Serial.print('\n');
          Serial.flush();

          int targetNum = 0;
          for (int i = 0; i < 4; i++) {
            if (workingPlayers[i] == allyIndex) continue;
            targetNum++;
            if (workingPlayers[i] == irIndex) break;
          }

          playTrack(trackBase[allyIndex] + targetNum);

          // Win Evaluation Loop Validation
          if (targetsHitCount >= 4 && totalScore >= 6) {
            isGameActive = false;
            isGameWon = true;
            
            playTrack(trackBase[allyIndex] + 6); // Play win track
            
            Serial.print("WIN\n");
            Serial.flush();
            
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("  ** YOU WIN ** ");
            lcd.setCursor(0, 1);
            lcd.print("Score:");
            lcd.print(totalScore);
            endScreenTime = millis();
            return;
          }
        }
        updateLCD();
      }
    }
  }
}