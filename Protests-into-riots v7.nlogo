breed [ agents an-agent ]
breed [ cops cop ]

globals [
  k                   ; factor for determining arrest probability
  threshold           ; by how much must G > N to make someone rebel?
  agents-left         ; how many agents have left
]

agents-own [
  risk-aversion       ; R, fixed for the agent's lifetime, ranging from 0-1 (inclusive)
  perceived-hardship  ; H, also ranging from 0-1 (inclusive)
  active?             ; if true, then the agent is actively rebelling
  ; jail-term           ; how many turns in jail remain? (if 0, the agent is not in jail)
  injury              ; if true, this agent is injured
  violent
  radicality
]

cops-own [
  risk-aversion       ; R, fixed for the agent's lifetime, ranging from 0-1 (inclusive)
  ; jail-term           ; how many turns in jail remain? (if 0, the agent is not in jail)
  injury              ; if true, this agent is injurd
  violent
]
patches-own [
  neighborhood        ; surrounding patches within the vision radius
]

to setup
  clear-all

  ; set globals
  set k 2.3
  set threshold 0.1
  set agents-left 0

  ask patches [
    ; make background a slightly dark gray
    set pcolor gray - 1
    ; cache patch neighborhoods
    set neighborhood patches in-radius vision
  ]

  if initial-cop-density + initial-protestors-density > 100 [
    user-message (word
      "The sum of INITIAL-COP-DENSITY and INITIAL-AGENT-DENSITY "
      "should not be greater than 100.")
    stop
  ]

  ; create cops
  create-cops round (initial-cop-density * .01 * count patches) [
    move-to one-of patches with [ not any? turtles-here ]
    ifelse (who < violent-cops) ;set certain percentage of cops to violent
      [set violent 1 ]
    [set violent 0]
    display-cop
  ]

  ; create agents
  create-agents round (initial-protestors-density * .01 * count patches) [
    move-to one-of patches with [ not any? turtles-here ]
    set heading 0
    set risk-aversion random-float 1.0
    set perceived-hardship random-float 1.0
    set radicality (random initial-protestors-density < radicality-protestors)
    set active? true
    ifelse ((who - count cops) < violent-protestors) ;set certain percentage of agents to violent
      [set violent 1 ]
    [set violent 0]
    ; set jail-term 0
    display-agent
  ]

  ; start clock and plot initial state of system
  reset-ticks
end


to go
  ask turtles [
    ; Rule M: Move to a random site within your vision
    if (breed = agents and injury = false) or breed = cops [ move ]
    ;   Rule A: Determine if each agent should be violent or quiet
    if breed = agents and injury = 0 [ determine-behavior injure leave]
    ;  Rule C: Cops injure a random active agent within their radius
    if breed = cops [ injure ]
    ; Rule L: If agent is inactive make it leave
    if breed = agents and active? = false [
      let x agents-left + 1
      set agents-left x
      die  ]
  ]
  ; Jailed agents get their term reduced at the end of each clock tick
  ; ask agents [ if injury = true [ set jail-term jail-term - 1 ] ]
  ; update agent display
  ask agents [ display-agent ]
  ask cops [ display-cop ]
  ; advance clock and update plots
  tick
end

; AGENT AND COP BEHAVIOR

; move to an empty patch
to move ; turtle procedure
  if movement? or breed = cops [
    ; move to a patch in vision; candidate patches are
    ; empty or contain only jailed agents
    let targets neighborhood with [
      not any? cops-here and all? agents-here [ injury = true ]
    ]
    if any? targets [ move-to one-of targets ]
  ]
end

; AGENT BEHAVIOR

to determine-behavior
  ;if someone is radical, they are more likely to get violent
  ifelse radicality = true [
    set violent (random-float 1.0 * 1.02)
  ] [
    set violent (random-float 1.0)
  ]
end

;to-report grievance
;  report perceived-hardship * (1 - government-legitimacy)
;end

to-report estimated-arrest-probability
  let c count cops-on neighborhood
  let a 1 + count (agents-on neighborhood) with [ active? ]
  ; See Info tab for a discussion of the following formula
  report 1 - exp (- k * floor (c / a))
end

to injure
  ;if this agents violent value is really high, they will start injuring someone
  if (violent >= 1 and random (1000 - violent-protestors) < 10) [ask one-of agents-on neighborhood [set injury true]]
end

to make-leave ;I want the agent to actually leave when it is not active, so it can't get injured but it doesn't work completely
  if active? = false[
    die
  ]
end
to leave ;people will leave if they observe violence close to them
  if any? (agents-on neighborhood) with [ injury = true ] [
    ifelse radicality = true [
      if random-float 1.0 < 0.05 [ ;radical people are less likely to leave
        set active? false
      ]
    ] [
      if random-float 1.0 < 0.1 [
        set active? false
      ]
    ]
  ]
end

; COP BEHAVIOR



; VISUALIZATION OF AGENTS AND COPS

to display-agent  ; agent procedure
  display-agent-2d
end

to display-agent-2d  ; agent procedure
  set shape "circle"
  set color green
  ifelse injury = true
      [ set color orange ] ;injured people turn orange
      [ set color scale-color green 0.2 1.5 -0.5]
    ; [ set color scale-color green grievance 1.5 -0.5 ]
end


to display-cop
  set color cyan
  set shape "triangle"
end


; Copyright 2004 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
325
10
733
419
-1
-1
10.0
1
10
1
1
1
0
1
1
1
0
39
0
39
1
1
1
ticks
30.0

BUTTON
10
205
80
238
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
250
80
283
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
210
410
300
455
active (red)
count agents with [active?] - count agents with [injury = true]
3
1
11

SLIDER
9
47
294
80
initial-cop-density
initial-cop-density
0.0
100.0
4.8
0.1
1
%
HORIZONTAL

MONITOR
10
410
110
455
left (green)
agents-left
1
1
11

MONITOR
180
200
263
245
# of cops
count cops
3
1
11

SLIDER
9
86
295
119
initial-protestors-density
initial-protestors-density
0.0
100.0
70.0
1.0
1
%
HORIZONTAL

MONITOR
95
200
177
245
# of agents
count agents
3
1
11

PLOT
10
458
345
618
All agent types
time
agents
0.0
20.0
0.0
150.0
true
true
"" ""
PENS
"left" 1.0 0 -10899396 true "" "plot agents-left"
"injuries" 1.0 0 -16777216 true "" "plot count agents with [injury = true]"
"active" 1.0 0 -2674135 true "" "plot (count agents with [active?] - count agents with [injury = true])"

TEXTBOX
10
26
100
44
Initial settings
11
0.0
0

SLIDER
9
124
214
157
radicality-protestors
radicality-protestors
0
100
14.0
1
1
%
HORIZONTAL

SWITCH
10
370
149
403
movement?
movement?
0
1
-1000

SLIDER
10
335
296
368
violent-cops
violent-cops
0
count cops
7.0
1
1
NIL
HORIZONTAL

SLIDER
9
293
295
326
violent-protestors
violent-protestors
0
count agents
0.0
1
1
NIL
HORIZONTAL

MONITOR
113
410
207
455
injured (black)
count agents with [injury = true]
17
1
11

SLIDER
9
161
214
194
vision
vision
0.0
10.0
7.0
.1
1
patches
HORIZONTAL

@#$#@#$#@
This model can simulate the effects of multiple factors on violence in protests. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person active
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -2674135 true false 195 135 240 30 210 15 165 120
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -2674135 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 105 135 60 30 90 15 135 120
Polygon -6459832 true false 195 15 270 60 270 75 195 30

person jailed
false
0
Circle -7500403 true true 110 5 80
Polygon -16777216 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -16777216 true false 195 90 210 150 195 180 165 105
Polygon -16777216 true false 105 90 90 150 105 180 135 105

person quiet
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -1184463 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1184463 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -1184463 true false 105 90 60 195 90 210 135 105

person soldier
false
10
Rectangle -7500403 true false 127 79 172 94
Polygon -13345367 true true 105 90 60 195 90 210 135 105
Polygon -13345367 true true 195 90 240 195 210 210 165 105
Circle -7500403 true false 110 5 80
Polygon -13345367 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 15 0 270 300 270

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
setup
repeat 5 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
