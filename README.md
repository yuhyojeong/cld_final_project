# 2024 2학기 논리설계 및 실험 프로젝트

## module 구성

- main module: 중앙 통제 역할
- 기능1 module: 시각 설정
- 기능2 module: 알람 시각 설정
- 기능3 module: 스톱워치
- 기능4 module: 알람 on/off + 알람 미니게임

## inputs / ouputs of each module

### main 모듈: `main.v` 파일

`Main`

      input [4:0] push, // 5 push buttons
      input [14:0] spdt,
      // 4 spdt switches for changing modes + 10 spdt switches for mini game + 1 spdt switch for reset
      input clk_osc,
      
      output reg [7:0] seg, // 7-segment control
      output reg [3:0] anode, // 7-segment control
      output [13:0] led, // 4 spdt leds + 10 mini game leds control
      output reg temp_led, // led for minigame only
      output clk_led // clock led control

`NumArrayTo7SegmentArray`

`NumTo7Segment`

### 기능1 모듈: `service_1.v` 파일

    input clk,
    input resetn,
    input spdt1,
    input push_u,
    input push_d,
    input push_l,
    input push_r,

    output reg [3:0] sel, // which segment is selected. msb (left) to lsb (right)
    output reg finish1, // service1 done
    output reg [15:0] num // segment number. msb(left) to lsb(right)

### 기능2 모듈: `service_2.v` 파일

    input clk,
    input resetn,
    input spdt2,
    input push_u,
    input push_d,
    input push_l,
    input push_r,

    output reg [3:0] sel, // which segment is selected. msb (left) to lsb (right)
    output reg finish2,
    output reg [15:0] alarm // alarm time. not displayed, but passed to top module.

### 기능3 모듈: `service_3.v` 파일

    input clk,        // Main clock
    input resetn,     // Reset signal (active low)
    input SPDT3,      // SPDT switch 3
    input push_m,     // Push button
    
    output reg [3:0] num1, // 7-segment digit 1 (tens of seconds)
    output reg [3:0] num2, // 7-segment digit 2 (units of seconds)
    output reg [3:0] num3, // 7-segment digit 3 (tens of hundredths)
    output reg [3:0] num4, // 7-segment digit 4 (units of hundredths)
    output reg led   // LED for SPDT3

### 기능4 모듈: `service_4.v` 파일
(단일화 하는 경우)

    input clk,
    input resetn,     // Reset signal (active low)
    input SPDT4,      // SPDT switch 3
    input [9:0] SPDTs
    input push_m,     // Push button
    
    input [15:0] current, // current_time  <br/>
    input [15:0] alarm, // alarm_time  <br/>

    output [2:0] alarm_state,
    //S0 3'b000 => alarm_mode_off. nothing to do
    //S0 3'b001 => alarm_mode_on. stanby. nothing to do
    //S0 3'b010 => alarm_on. Flash all Segments and LEDs
    //S0 3'b100 => minigame. Display count_state and SPDT_LED.

    output [15:0] count_state, //Seg LEDs
    output [9:0] SPDT_LED, // above SPDTs
    output finish4 

# 기능별 구현.

## 0. 기본 동작
1. 7 segment에 시각 출력
   mm:ss (59:59=>00:00)
2. 가장 오른쪽 LED에 clk 점멸(clk period :1s)

### 초기 상태
1. 7 segment에 00:00 출력
2. 가장 오른쪽 LED에 clock 출력
3. 가장 오른쪽 SPDT switch는 reset으로 이용


## 1. 기능 1: 시각 설정
 SPDT switch 1과 push button switch 4개 사용  
■ 1. SPDT switch 1 on  
❑ SPDT switch 1 위의 LED도 함께 on  
■ 2. 첫 번째 7 segment 점멸 (clk)  
■ 3. 위, 아래 push button 통해 값 조절  
■ 4. 오른쪽, 왼쪽 push button 통해 다른 7 segment 선택  
❑ 선택된 7 segment 점멸 (clk)  
■ 5. 3~4 과정을 반복하다가 시각 설정이 완료되면 SPDT switch off  
■ 6. switch off 후엔 현재 시각 표시  

## 2. 기능 2: 알람 시각 설정
❑ SPDT switch 2와 push button switch 4개 사용  
❑ 기능 1과 과정은 동일  
❑ SPDT switch 2를 off하면 다시 현재 시각으로 변경  
■ 현재 시각: 기능 1을 통해 설정해 놓은 시각  

## 3. 스톱워치
❑ SPDT switch 3와 push button switch 1개(가운데) 사용  
■ 1. SPDT switch 3 on  
❑ Switch 위의 LED도 함께 on  
❑ 7 segment = 00:00  
■ 2. Push button switch 한번 누르면 스톱워치 시작  
❑ SS:ss (S : 1초 단위, s : 1/100초 단위, 최대 99:99)  
■ 3. Push button switch 한번 더 누르면 스톱워치 일시정지 후
시간 표시  
■ 4. 2~3의 과정을 반복하다가 SPDT switch off와 스톱워치 종료  
❑ 단, SPDT switch를 off 하기 전엔 스톱워치를 유지  
■ 5. switch off 후엔 현재 시각 표시  

## 4. 알람 on/off
❑ SPDT switch 4 사용  
■ Switch on : 알람 on  
■ Switch off : 알람 off  
❑ 알람이 on 상태로 되어 있고, 현재 시각과 알람 설정 시각이
같을 때 알람 동작  
■ 모든 LED와 7 segment가 점멸  
❑ 알람을 종료하기 위해선, 미니게임을 진행해야 함  

### 알람 미니게임.
❑ 알람을 종료하기 위해서는 미니게임을 진행해야 함  
■ 가운데 push button을 누르면 게임 시작  
❑ 모든 LED, 7 segment의 점멸 종료  
❑ 7 segment = 0000 (count, 정답 횟수 표시)  
■ LED 10개 중 랜덤으로 한 개의 LED가 켜짐  
❑ 랜덤으로 선택된 LED가 2초 동안 켜지는 과정 반복  
▪ 복원추출  
■ 해당 LED 아래의 SPDT switch를 on하면 count + 1  
❑ count를 7 segment에 표시  
❑ 실패할 경우, count를 0으로 초기화한 뒤, 다시 미니 게임 진행  
▪ 여러 개의 SPDT switch를 동시에 on 상태로 둘 경우도 실패  
■ count가 3이 되면, 알람이 종료되고 기본 기능(시각 표시) 동작  
