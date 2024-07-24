void setup() {
  Serial.begin(9600);
  for (int pin = 2; pin <= 9; pin++) {
    pinMode(pin, OUTPUT);
  }
}

void loop() {
  if (Serial.available() > 0) {
  
    String data = Serial.readStringUntil('\n');
    int commaIndex = data.indexOf(',');
	
	String triggerNumberStr = data.substring(0, commaIndex);
    String INDelaymsStr = data.substring(commaIndex + 1);
  
    int triggerNumber = triggerNumberStr.toInt();
    int INDelayms =  INDelaymsStr.toInt();

    if (triggerNumber == 0) {
      for (int pin = 2; pin <= 9; pin++) {
        digitalWrite(pin, LOW);
      }
    }
    else if (triggerNumber >= 1 && triggerNumber <= 255) {
      for (int i = 0; i < 8; i++) {
        int pinState = bitRead(triggerNumber, 0 + i);
        digitalWrite(i + 2, pinState);
      }
      
      if (INDelayms > 0) {
        delay(INDelayms); 
        for (int i = 0; i < 8; i++) {
          int pinState = bitRead(triggerNumber, 0 + i);
          if (pinState) {
            digitalWrite(i + 2, LOW);
          }
        }
      }
    }
    while (Serial.available() > 0) {
      char trash = Serial.read();
    }
  }
}