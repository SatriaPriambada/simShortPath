; global variables used
globals
[
  open ; the open list of patches
  closed ; the closed list of patches
  optimal-path ; the optimal path, list of patches from source to destination
]

breed [ pieces piece ]   ;; pieces Tetris L

; patch variables used
patches-own
[
  parent-patch ; patch's predecessor
  f ; the value of knowledge plus heuristic cost function f()
  g ; the value of knowledge cost function g()
  h ; the value of heuristic cost function h()
]

; turtle variables used
turtles-own
[
  path ; the optimal path from source to destination
  current-path ; part of the path that is left to be traversed
]

pieces-own [
  x y      ;; these are the piece's offsets relative to turtle 0
]

to setup-l ;;Piece Procedure
  if (who mod 4 = 1) [ set x  1 set y  0 ]
  if (who mod 4 = 2) [ set x -1 set y  0 ]
  if (who mod 4 = 3) [ set x -1 set y -1 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Overlap prevention Reporters ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report clear? [p]  ;; p is a patch
  if p = nobody [ report false ]
  report (not any? pieces-on p) and ([pcolor] of p != gray)
end

to-report clear-at? [xoff yoff]
  report all? pieces [clear? patch-at xoff yoff]
end

to-report rotate-left-clear?
  report all? pieces [clear? patch-at (- y) x]
end

to-report rotate-right-clear?
  report all? pieces [clear? patch-at y (- x)]
end

to rotate-me-right  ;; Piece Procedure
  let oldx x
  let oldy y
  set x oldy
  set y (- oldx)
  set xcor ([xcor] of turtle 0) + x
  set ycor ([ycor] of turtle 0) + y
end

to rotate-me-left  ;; Piece Procedure
  let oldx x
  let oldy y
  set x (- oldy)
  set y oldx
  set xcor ([xcor] of turtle 0) + x
  set ycor ([ycor] of turtle 0) + y
end


; setup the world
to Setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks ;; clear everything (the view and all the variables)
  create-source-and-destination
end

; create the source and destination at two random locations on the view
to create-source-and-destination
  repeat population[
    ask one-of patches with [pcolor = black]
    [
      set pcolor blue
      ;set plabel "source"
      sprout 1
      [
        set color red
        ;setup-l
        set size 3
        set shape "L"
        pd
      ]
    ]
  ]
  ask one-of patches with [pcolor = black]
  [
    set pcolor green
    set plabel "destination"
  ]
end

; draw the selected maze elements on the view
to draw
  if mouse-inside?
    [
      ask patch mouse-xcor mouse-ycor
      [
        sprout 1
        [
          set shape "square"
          die
        ]
      ]

      ;draw obstacles
      if Select-element = "obstacles"
      [
        if mouse-down?
        [
          if [pcolor] of patch mouse-xcor mouse-ycor = black or [pcolor] of patch mouse-xcor mouse-ycor = brown or [pcolor] of patch mouse-xcor mouse-ycor = yellow
          [
            ask patch mouse-xcor mouse-ycor
            [
              set pcolor white
            ]
          ]
        ]
      ]

      ;erase obstacles
      if Select-element = "erase obstacles"
      [
        if mouse-down?
        [
          if [pcolor] of patch mouse-xcor mouse-ycor = white
          [
            ask patch mouse-xcor mouse-ycor
            [
              set pcolor black
            ]
          ]
        ]
      ]

      ;draw source patch
      if Select-element = "source"
      [
        if mouse-down?
        [
          let m-xcor mouse-xcor
          let m-ycor mouse-ycor
          if [plabel] of patch m-xcor m-ycor != "destination"
          [
            ask patches with [plabel = "source"]
            [
              set pcolor black
              set plabel ""
            ]
            ask turtles
            [
              die
            ]
            ask patch m-xcor m-ycor
            [
              set pcolor blue
              set plabel "source"
              sprout 1
              [
                set color red
                pd
              ]
            ]
          ]
        ]
      ]

      ;draw destination patch
      if Select-element = "destination"
        [
          if mouse-down?
            [
              let m-xcor mouse-xcor
              let m-ycor mouse-ycor

              if [plabel] of patch m-xcor m-ycor != "source"
              [
                ask patches with [plabel = "destination"]
                [
                  set pcolor black
                  set plabel ""
                ]
                ask patch m-xcor m-ycor
                [
                  set pcolor green
                  set plabel "destination"
                ]
              ]
            ]
        ]
    ]
end

; call the path finding procedure, update the turtle (agent) variables, output text box
; and make the agent move to the destination via the path found
to find-shortest-path-to-destination
  reset-ticks
  ask turtles
  [
    ;move-to one-of patches with [pcolor = blue]
    set path find-a-path patch-here one-of patches with [plabel = "destination"]
    set optimal-path path
    set current-path path
  ]
  output-show (word "Shortest path length : " length optimal-path)
  move
end

to djikstra
  reset-ticks
  ask one-of turtles
  [
    move-to one-of patches with [plabel = "source"]
    set path find-a-path one-of patches with [plabel = "source"] one-of patches with [plabel = "destination"]
    set optimal-path path
    set current-path path
  ]
  output-show (word "Shortest path length : " length optimal-path)
  move
end


; the actual implementation of the A* path finding algorithm
; it takes the source and destination patches as inputs
; and reports the optimal path if one exists between them as output
to-report find-a-path [ source-patch destination-patch]

  ; initialize all variables to default values
  let search-done? false
  let search-path []
  let current-patch 0
  set open []
  set closed []

  ; add source patch in the open list
  set open lput source-patch open

  ; loop until we reach the destination or the open list becomes empty
  while [ search-done? != true]
  [
    ifelse length open != 0
    [
      ; sort the patches in open list in increasing order of their f() values
      set open sort-by [[f] of ?1 < [f] of ?2] open

      ; take the first patch in the open list
      ; as the current patch (which is currently being explored (n))
      ; and remove it from the open list
      set current-patch item 0 open
      set open remove-item 0 open

      ; add the current patch to the closed list
      set closed lput current-patch closed

      ; explore the Von Neumann (left, right, top and bottom) neighbors of the current patch
      ask current-patch
      [
        ; if any of the neighbors is the destination stop the search process
        ifelse any? neighbors4 with [ (pxcor = [ pxcor ] of destination-patch) and (pycor = [pycor] of destination-patch)]
        [
          set search-done? true
        ]
        [
          ; the neighbors should not be obstacles or already explored patches (part of the closed list)
          ask neighbors4 with [ pcolor != white and (not member? self closed) and (self != parent-patch) ]
          [
            ; the neighbors to be explored should also not be the source or
            ; destination patches or already a part of the open list (unexplored patches list)
            if not member? self open and self != source-patch and self != destination-patch
            [
              set pcolor 45

              ; add the eligible patch to the open list
              set open lput self open

              ; update the path finding variables of the eligible patch
              set parent-patch current-patch
              set g [g] of parent-patch  + 1
              set h distance destination-patch
              set f (g + h)
            ]
          ]
        ]
        if self != source-patch
        [
          set pcolor 35
        ]
      ]
    ]
    [
      ; if a path is not found (search is incomplete) and the open list is exhausted
      ; display a user message and report an empty search path list.
      user-message( "A path from the source to the destination does not exist." )
      report []
    ]
  ]

  ; if a path is found (search completed) add the current patch
  ; (node adjacent to the destination) to the search path.
  set search-path lput current-patch search-path

  ; trace the search path from the current patch
  ; all the way to the source patch using the parent patch
  ; variable which was set during the search for every patch that was explored
  let temp first search-path
  while [ temp != source-patch ]
  [
    ask temp
    [
      set pcolor 85
    ]
    set search-path lput [parent-patch] of temp search-path
    set temp [parent-patch] of temp
  ]

  ; add the destination patch to the front of the search path
  set search-path fput destination-patch search-path

  ; reverse the search path so that it starts from a patch adjacent to the
  ; source patch and ends at the destination patch
  set search-path reverse search-path

  ; report the search path
  report search-path
end

; make the turtle traverse (move through) the path all the way to the destination patch
to move
    ask turtles
    [
      while [length current-path != 0]
      [
        go-to-next-patch-in-current-path
        pd
        wait 0.05

      ]
      if length current-path = 0
      [
        pu
      ]
    ]
end

to go-to-next-patch-in-current-path
  face first current-path
  repeat 10
  [
    fd 0.1
  ]
  move-to first current-path
  if [plabel] of patch-here != "source" and  [plabel] of patch-here != "destination"
  [
    ask patch-here
    [
      set pcolor black
    ]
  ]
  set current-path remove-item 0 current-path
end

; clear the view of everything but the source and destination patches
to clear-view
  cd
  ask patches with[ plabel != "source" and plabel != "destination" ]
  [
    set pcolor black
  ]
end

; load a maze from the file system
to load-maze [ maze ]
  if maze != false
  [
    ifelse (item (length maze - 1) maze = "g" and item (length maze - 2) maze = "n" and item (length maze - 3) maze = "p" and item (length maze - 4) maze = ".")
    [
      save-maze "temp.png"
      ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
      import-pcolors maze
      ifelse count patches with [pcolor = blue] = 1 and count patches with [pcolor = green] = 1
      [
        ask patches
        [
          set plabel ""
        ]
        ask turtles
        [
          die
        ]
        ask one-of patches with [pcolor = blue]
        [
          set plabel "source"
          sprout 1
          [
            set color red
            pd
          ]
        ]
        ask one-of patches with [pcolor = green]
        [
          set plabel "destination"
        ]
      ]
      [
        ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
        user-message "The selected image is not a valid maze."
        load-maze "temp.png"
        ;;clear-view
      ]
    ]
    [
      user-message "The selected file is not a valid image."
    ]
  ]
end

; save a maze as a PNG image into the system
to save-maze [filename]
  if any? patches with [pcolor != black]
  [
    clear-unwanted-elements
    export-view (filename)
    restore-labels
  ]
end

; clear the view of everything but the obstacles, source and destination patches
; so that the view can be saved as a PNG image
to clear-unwanted-elements
  if any? patches with [pcolor = brown or pcolor = yellow  ]
  [
    ask patches with [pcolor = brown or pcolor = yellow  ]
    [
      set pcolor black
    ]
  ]
  if any? patches with [pcolor = blue]
  [
    ask one-of patches with [pcolor = blue]
    [
      set plabel ""
    ]
  ]
  if any? patches with [pcolor = green]
  [
    ask one-of patches with [pcolor = green]
    [
      set plabel ""
    ]
  ]
  clear-drawing
  ask turtles
  [
    die
  ]
end

; re-label the source and destination patches ones
; the maze image file has been saved
to restore-labels
  ask one-of patches with [pcolor = blue]
  [
    set plabel "source"
    sprout 1
    [
      set color red
      pd
    ]
  ]
  ask one-of patches with [pcolor = green]
  [
    set plabel "destination"
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
229
39
991
650
17
13
21.5
1
10
1
1
1
0
0
0
1
-17
17
-13
13
0
0
1
ticks
30.0

BUTTON
6
39
181
76
NIL
Setup
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
8
160
181
199
Optimal path A*
find-shortest-path-to-destination
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
919
116
1143
144
patch-color = yellow : patch is in open list
11
44.0
0

TEXTBOX
658
184
808
202
NIL
11
0.0
1

TEXTBOX
919
145
1147
173
patch-color = brown : patch is in closed list
11
34.0
1

TEXTBOX
919
173
1132
201
patch-color = cyan : patch is in search path
11
84.0
1

TEXTBOX
918
38
1171
66
patch-color = green : patch is the destination patch
11
54.0
1

TEXTBOX
918
10
1142
38
patch-color = blue : patch is the source patch
11
104.0
1

TEXTBOX
919
65
1156
93
patch-color = black : patch is not yet explored
11
0.0
1

BUTTON
8
125
181
158
Draw elements
draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
7
78
181
123
Select-element
Select-element
"source" "destination" "obstacles" "erase obstacles"
2

TEXTBOX
919
91
1155
119
patch-color = white : patch is an obstacle
11
124.0
1

BUTTON
8
446
181
479
Clear view
clear-view
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
193
10
967
35
Implementation of A* path finding algorithm in NetLogo using exact heuristic function.
16
0.0
1

BUTTON
103
485
168
518
Load
load-maze user-file
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
21
486
81
519
Save
save-maze word user-new-file \".png\"
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
9
204
182
245
Optimal path Djikstra
djikstra
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
257
185
290
Population
Population
0
100
5
1
1
NIL
HORIZONTAL

@#$#@#$#@
## TUGAS 2 NETLOGO

Tugas 2 adlah membuat simulasi model pencarian jarak dengan A* path finding algorithm dan Djikstra. Fungsi heuristic (h(n)) mengembalikan jarak dari suatu titik menuju goal. Fungsi jarak (f(n)) beruguna untuk menentukan jarak yang sudah diambil dari titik awal. Jarak yang diambil adalah penjumblahan terkecil antara 2 buah fungsi ini, atau dengan kata lain menghasilkan jarak terpendek menuju goal.

## THE INTERFACE
Berikut adalah user intergace yang dimiliki oleh program:

-> Setup : Tombol ini digunakan untuk membersihkan tampilan sebelum simulasi dimulai.

-> Select-element : Bagian ini digunakan untuk memilih komponen yang ingin digambarkan pada peta layar. Kompenen yang dapat dipilih antaralain:
	+> source: Titik awal dari objek.

	+> destination: Tujuan final objek

	+> obstacles: Halangan yang tidak dapat dileawti objek

	+> erase obstacles: Untuk menghilangkan objek

-> Draw elements : Tombol ini digunakan untuk menggambar komponen yang telah dipilih pada select-ement. Cara penggunaan adalah dengan menekan tombol ini dan lalu gunakan mouse untuk menggambar pada layar. Setelah selesai tekan tombol ini sekali lagi.

-> Find an optimal path (A* dan Dijkstra): Tombol ini akan menentukan jalan terdekat melalui algoritma A* atau Dijkstra

-> Clear View : Tombol untuk membersihkan layar.

-> Save this maze : Tombol untuk menyimpan peta dalam bentuk png.

-> Load a maze : Tombol untuk memanggil peta yang telah dibuat sebelumnya dalam bentuk png.

-> Warna :
Putih : Rintangan
Biru : Source
Hijau : Tujuan


## HOW TO USE IT

1. Tekan setup button,pilih komponen yang ingin digambar dari select-element chooser.
2. Aktifkan Draw elements button. Gunakan mouse untuk menggambar
3. Tekan "Find an optimal path" button untuk melihat simulasi.
4. Gunakan "Save this maze" untuk menyimpan peta dan "Load a maze" untuk memanggil peta yang ada



## CREDITS AND REFERENCES

Astardemo.nlogo from Netlogo tutorial

Russell, S. J.; Norvig, P. (2003). Artificial Intelligence: A Modern Approach. Upper Saddle River, N.J.: Prentice Hall. pp. 97�104. ISBN 0-13-790395-2

http://en.wikipedia.org/wiki/A*_search_algorithm
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

l
true
0
Rectangle -2674135 false false 90 30 210 90
Rectangle -2674135 true false 90 30 210 90
Rectangle -2674135 true false 90 30 150 210

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
Polygon -7500403 true true 150 30 15 255 285 255

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
NetLogo 5.3.1
@#$#@#$#@
setup-corner
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
