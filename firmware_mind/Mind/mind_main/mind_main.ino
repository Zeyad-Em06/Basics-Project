#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <DFRobotDFPlayerMini.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
SoftwareSerial dfSerial(11, 9);
DFRobotDFPlayerMini dfPlayer;

#define RESTART_BUTTON  2
#define SHOOT_BUTTON    4

const char* playerNames[] = {"SHOKRY", "ZEYAD", "MOAZ", "YASSIN", "ADHAM"};
int trackBase[]            = {1, 8, 15, 22, 29};

int workingPlayers[] = {0, 1, 2, 3}; // SHOKRY, ZEYAD, MOAZ, YASSIN (ADHAM removed)

enum GameState { STATE_INIT, STATE_PLAYING, STATE_WIN, STATE_LOSE };
GameState state = STATE_INIT;

int  allyIndex       = -1;
bool targetsHit[5]   = {false, false, false, false, false};
int  targetsHitCount = 0;
int  totalScore      = 0;
bool waitingForHit   = false;
bool ballIsBig       = true;
unsigned long endScreenTime = 0;

void playTrack(int trackNum) {
  dfSerial.listen();
  dfPlayer.playMp3Folder(trackNum);
}

void sendToWorker(char a, char b, char c, char d) {
  Serial.write(a);
  Serial.write(b);
  Serial.write(c);
  Serial.write(d);
  Serial.flush();
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

  sendToWorker('R','E','S','T');
  while (Serial.available()) Serial.read();

  randomSeed(analogRead(A0));
  allyIndex = random(0, 5);

  Serial.write('A');
  Serial.write('L');
  Serial.write('L');
  Serial.write('Y');
  Serial.write((char)allyIndex);
  Serial.flush();

  playTrack(trackBase[allyIndex]);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Ally:");
  lcd.print(playerNames[allyIndex]);
  lcd.setCursor(0, 1);
  lcd.print("Sc:0  0/4 [BIG]");

  state = STATE_PLAYING;
}

void setup() {
  pinMode(RESTART_BUTTON, INPUT_PULLUP);
  pinMode(SHOOT_BUTTON,   INPUT_PULLUP);

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

  Serial.begin(9600);
  delay(500);
  while (Serial.available()) Serial.read();

  state = STATE_INIT;
}

void loop() {

  if (digitalRead(RESTART_BUTTON) == LOW) {
    dfPlayer.stop();
    while (Serial.available()) Serial.read();
    delay(200);
    state = STATE_INIT;
    return;
  }

  switch (state) {

    case STATE_INIT:
      initGame();
      break;

    case STATE_PLAYING: {

      if (digitalRead(SHOOT_BUTTON) == LOW && !waitingForHit) {
        sendToWorker('F','I','R','E');
        waitingForHit = true;

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("  ** FIRE! **  ");
        lcd.setCursor(0, 1);
        lcd.print(ballIsBig ? "Ball:BIG  +1pt" : "Ball:SML  +2pt");

        while (digitalRead(SHOOT_BUTTON) == LOW);
        delay(200);
      }

      if (Serial.available() && waitingForHit) {
        char hit = Serial.read();
        int irIndex = hit - '1';

        if (irIndex >= 0 && irIndex <= 4) {
          waitingForHit = false;

          bool thisBallBig = ballIsBig;
          ballIsBig = !ballIsBig;

          if (irIndex == allyIndex) {
            updateLCD();
            break;
          }

          if (!targetsHit[irIndex]) {
            targetsHit[irIndex] = true;
            targetsHitCount++;

            int points = thisBallBig ? 1 : 2;
            totalScore += points;

            int targetNum = 0;
            for (int i = 0; i < 4; i++) {
              if (workingPlayers[i] == allyIndex) continue;
              targetNum++;
              if (workingPlayers[i] == irIndex) break;
            }

            playTrack(trackBase[allyIndex] + targetNum);

            if (targetsHitCount >= 4 && totalScore >= 6) {
              playTrack(trackBase[allyIndex] + 6);
              lcd.clear();
              lcd.setCursor(0, 0);
              lcd.print("  ** YOU WIN ** ");
              lcd.setCursor(0, 1);
              lcd.print("Score:");
              lcd.print(totalScore);
              endScreenTime = millis();
              state = STATE_WIN;
              break;
            }
          }

          updateLCD();
        }
      }
      break;
    }

    case STATE_WIN:
      if (millis() - endScreenTime >= 5000) {
        state = STATE_INIT;
      }
      break;

    case STATE_LOSE:
      if (millis() - endScreenTime >= 5000) {
        state = STATE_INIT;
      }
      break;
  }
}