#include "SoftwareSerial.h"
SoftwareSerial MyBlue(0,1); // TX | RX 
#define ldr A0
#define door A1
#define baby A2
int BabyTemp = 0;
int IncTemp = 0;
void setup() 
{ 
 Serial.begin(9600); 
 MyBlue.begin(38400);  //Baud Rate for AT-command Mode.  
 pinMode(ldr,INPUT);
} 
void loop() 
{ 
  int ldrStatus = analogRead(ldr);
  int doorStatus = analogRead(door);
  int babySleep = analogRead(baby);
 //from bluetooth to Terminal. 
 if (MyBlue.available()) 
   Serial.write(MyBlue.read());
 //from termial to bluetooth 
 if (Serial.available())
   MyBlue.write(Serial.read());
   
 if(BabyTemp < 20 && IncTemp > -20 && (ldrStatus <600 && ldrStatus > 400) && doorStatus < 40 && babySleep > 600){
  Serial.println("");
   Serial.print("Baby's Temp.: ");
   Serial.print(BabyTemp);
   Serial.println(" oC");
   Serial.println("\n\n");
   Serial.print("Incubator Temp.: ");
   Serial.print(IncTemp);
   Serial.println(" oC");
   Serial.println("\n\n");
   Serial.print("Light is normal");
   Serial.println("\n\n");
   Serial.print("Door is closed");
   Serial.println("\n\n");
   Serial.print("The baby slept");

  delay(1000);
 }
 else if (doorStatus >= 40){
  Serial.print("");
  Serial.print("The Door is open");
 delay(1000);
 }
 else if (ldrStatus >= 600 || ldrStatus <= 400){
  Serial.print("");
  Serial.print("Light level is out of range");
 delay(1000);
 }
 else if (doorStatus >= 40){
    Serial.print("");
  Serial.print("The Incubator is empty");

 delay(1000);
 }
 
}
