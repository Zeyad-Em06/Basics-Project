#include <Servo.h>

// Hardware Pin Assignments based on your pattern constraints
const int IR_PINS[5] = {4, 6, 8, 10, 12}; 
const int RELAY_SOLENOID_PIN = 2;
const int SERVO_MOTOR_PIN = 9;

Servo sortingServo;

// Sensor state tracking to detect active-low edge drops
bool lastSensorState[5] = {HIGH, HIGH, HIGH, HIGH, HIGH};

// Non-blocking solenoid pulse management parameters
unsigned long solenoidTriggerTime = 0;
const unsigned long SOLENOID_PULSE_DURATION = 120; // 120ms power window
bool isSolenoidActive = false;

// Non-blocking mechanical reload tracking variables
unsigned long reloadStartTime = 0;
const unsigned long SERVO_PUSH_DURATION = 300;   // Time to slide round into chamber
const unsigned long SERVO_RETURN_DURATION = 600; // Total stroke duration
bool isReloading = false;

// Shared global rules parsed from the Mind Uno
int mindAssignedAllyIndex = -1;

void setup() {
  // Direct face-to-face wired UART connection back to the Mind Uno
  Serial.begin(9600);
  
  // Solenoid Safety Lock: Active-low modules must initialize HIGH to avoid boot firing
  pinMode(RELAY_SOLENOID_PIN, OUTPUT);
  digitalWrite(RELAY_SOLENOID_PIN, HIGH);
  
  for (int i = 0; i < 5; i++) {
    pinMode(IR_PINS[i], INPUT_PULLUP);
  }
  
  sortingServo.attach(SERVO_MOTOR_PIN);
  sortingServo.write(0); // Neutral gate alignment index
}

void loop() {
  unsigned long currentMillis = millis();
  
  // ==========================================
  // 1. SOLENOID BURST CUTOFF TIMELINE
  // ==========================================
  if (isSolenoidActive && (currentMillis - solenoidTriggerTime >= SOLENOID_PULSE_DURATION)) {
    digitalWrite(RELAY_SOLENOID_PIN, HIGH); // Safely release the active-low coil drive
    isSolenoidActive = false;
    
    // Hand execution smoothly down to the physical reloader
    sortingServo.write(45); // Open hopper track gate
    reloadStartTime = currentMillis;
    isReloading = true;
  }
  
  // ==========================================
  // 2. FLAT MECHATRONIC RELOAD TIMELINE
  // ==========================================
  if (isReloading) {
    unsigned long elapsedTime = currentMillis - reloadStartTime;
    
    if (elapsedTime >= SERVO_PUSH_DURATION && elapsedTime < SERVO_RETURN_DURATION) {
      sortingServo.write(0); // Close chamber track gate
    }
    else if (elapsedTime >= SERVO_RETURN_DURATION) {
      isReloading = false; // Mechanism clear, ready to cycle next fire pass
    }
  }
  
  // ==========================================
  // 3. MULTI-BYTE COMMAND PACKET PARSER
  // ==========================================
  if (Serial.available() >= 4) {
    char b1 = Serial.read();
    char b2 = Serial.read();
    char b3 = Serial.read();
    char b4 = Serial.read();
    
    // Process: sendToWorker('F','I','R','E')
    if (b1 == 'F' && b2 == 'I' && b3 == 'R' && b4 == 'E') {
      if (!isSolenoidActive && !isReloading) {
        digitalWrite(RELAY_SOLENOID_PIN, LOW); // Drop pin low to activate relay
        solenoidTriggerTime = currentMillis;
        isSolenoidActive = true;
      }
    }
    // Process: sendToWorker('R','E','S','T')
    else if (b1 == 'R' && b2 == 'E' && b3 == 'S' && b4 == 'T') {
      digitalWrite(RELAY_SOLENOID_PIN, HIGH); // Hard safety isolation override
      isSolenoidActive = false;
      isReloading = false;
      sortingServo.write(0); // Return sorting channel to index base
      mindAssignedAllyIndex = -1;
    }
    // Process: Mind's sequential setup transmission ('A','L','L','Y' + raw value)
    else if (b1 == 'A' && b2 == 'L' && b3 == 'L' && b4 == 'Y') {
      // Loop execution wait ensures trailing data payload is loaded in buffer
      while (Serial.available() == 0); 
      mindAssignedAllyIndex = Serial.read(); // Read assignment payload (0 to 4)
    }
  }
  
  // ==========================================
  // 4. EVEN-PATTERN HARDWARE SENSOR EVALUATION
  // ==========================================
  for (int i = 0; i < 5; i++) {
    bool currentReading = digitalRead(IR_PINS[i]);
    
    // Detect edge transitions (IR Beam broken = falling edge LOW)
    if (currentReading == LOW && lastSensorState[i] == HIGH) {
      // Mind maps targets using characters '1' through '5'
      char targetHitToken = (char)('1' + i);
      Serial.write(targetHitToken);
      Serial.flush(); // Instantly push up the TX hardware trace line
    }
    lastSensorState[i] = currentReading;
  }
}