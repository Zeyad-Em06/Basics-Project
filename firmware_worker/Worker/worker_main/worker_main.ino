#include <Servo.h>

// Even pattern hardware pin layouts
const int IR_PINS[5] = {4, 6, 8, 10, 12}; 
const int RELAY_SOLENOID_PIN = 2;
const int SERVO_MOTOR_PIN = 9;

Servo sortingServo;

// Tracking arrays for edge-trigger filtering (Active-Low IR Sensors)
bool lastSensorState[5] = {HIGH, HIGH, HIGH, HIGH, HIGH};

// Solenoid Pulse Timers
unsigned long solenoidTriggerTime = 0;
const unsigned long SOLENOID_PULSE_DURATION = 120; // 120ms power cycle
bool isSolenoidActive = false;

// Mechatronic Reload Timeline (Completely flat alternative to state machines)
unsigned long reloadStartTime = 0;
const unsigned long SERVO_PUSH_DURATION = 300;   // Arm sweep out time window
const unsigned long SERVO_RETURN_DURATION = 600; // Total arm timeline back home
bool isReloading = false;

void setup() {
  Serial.begin(9600); // Direct hardware UART cross link to Mind Uno
  
  pinMode(RELAY_SOLENOID_PIN, OUTPUT);
  digitalWrite(RELAY_SOLENOID_PIN, HIGH); // Force HIGH (Active-Low relay safe off-state)
  
  for (int i = 0; i < 5; i++) {
    pinMode(IR_PINS[i], INPUT_PULLUP);
  }
  
  sortingServo.attach(SERVO_MOTOR_PIN);
  sortingServo.write(0); // Set mechanism home gate locked
}

void loop() {
  unsigned long currentMillis = millis();
  
  // 1. SOLENOID BURST CUTOFF SAFETY TIMELINE
  if (isSolenoidActive && (currentMillis - solenoidTriggerTime >= SOLENOID_PULSE_DURATION)) {
    digitalWrite(RELAY_SOLENOID_PIN, HIGH); // Force relay off safely
    isSolenoidActive = false;
    
    // Hand down loading instructions to servo timeline instantly
    sortingServo.write(45); // Open track gate chute
    reloadStartTime = currentMillis;
    isReloading = true;
  }
  
  // 2. FLAT MECHATRONIC RELOAD TIMELINE HANDLING 
  if (isReloading) {
    unsigned long elapsedTime = currentMillis - reloadStartTime;
    
    if (elapsedTime >= SERVO_PUSH_DURATION && elapsedTime < SERVO_RETURN_DURATION) {
      sortingServo.write(0); // Sweep chamber track gate block back home
    }
    else if (elapsedTime >= SERVO_RETURN_DURATION) {
      isReloading = false; // Reset cycle flag completely
    }
  }
  
  // 3. PARSE INBOUND SINGLE-BYTE SERIAL COMMAND TOKENS
  if (Serial.available() > 0) {
    char commandToken = Serial.read();
    
    if (commandToken == 'F') { // Fire Request
      if (!isSolenoidActive && !isReloading) {
        digitalWrite(RELAY_SOLENOID_PIN, LOW); // Trigger active-low relay coil
        solenoidTriggerTime = currentMillis;
        isSolenoidActive = true;
      }
    }
    else if (commandToken == 'R') { // Reset System Request
      digitalWrite(RELAY_SOLENOID_PIN, HIGH);
      isSolenoidActive = false;
      isReloading = false;
      sortingServo.write(0);
    }
  }
  
  // 4. SENSOR SCAN MATRIX EVALUATIONS (Active-Low falling edge loop tracking)
  for (int i = 0; i < 5; i++) {
    bool currentReading = digitalRead(IR_PINS[i]);
    
    if (currentReading == LOW && lastSensorState[i] == HIGH) {
      char targetHitToken = (char)('1' + i); // Formats array index dynamically to chars '1'-'5'
      Serial.write(targetHitToken);
      Serial.flush();
    }
    lastSensorState[i] = currentReading;
  }
}