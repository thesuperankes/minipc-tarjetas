NPF   = 80
PROF  = { 1, 2, 3, 4 }
TMAX  = { 30, 90, 180, 300 }
RUIDO = { 90, 25, 0, 0 }
INF, MATE = 99999, 30000
NO = { 8, 12, 19, 21, -8, -12, -19, -21 }
DO = { 9, 11, -9, -11 }
OO = { 1, -1, 10, -10 }
KO = { 1, -1, 10, -10, 9, 11, -9, -11 }
OF = { nil, NO, DO, OO, KO, KO }
VB = { 0, 300, 315, 500, 900, 0 }
CMT = { [21] = 13, [25] = 12, [28] = 14, [91] = 7, [95] = 3, [98] = 11 }
LADO = 0x5BD1E99
SIL = {
{ ".......", "..###..", "..###..", "...#...", "..###..", ".#####.", ".#####." },
{ "...#...", "..###..", ".#####.", "##.###.", "...###.", "..####.", ".#####." },
{ "...#...", "..###..", ".#####.", ".##.##.", ".#####.", "..###..", ".#####." },
{ ".#.#.#.", ".#####.", "..###..", "..###..", "..###..", ".#####.", ".#####." },
{ "...#...", "#.###.#", ".#####.", "..###..", "..###..", ".#####.", "#######" },
{ "...#...", "..###..", "...#...", ".#####.", "..###..", "..###..", ".#####." },
}
function _init()
B, MV, U, RK = {}, {}, {}, {}
LJ, RM, RS, PZ, DS, PH, GH, V = {}, {}, {}, {}, {}, {}, {}, {}
fr, rep, mi, parp = 0, 0, 3, 0
lvl = mid(1, dget(2) or 0, 4)
csel = (dget(3) == 1) and -1 or 1
textosMenu()
estado = "menu"
end
function nueva()
for i = 0, 119 do B[i] = 7 end
local fila = { 4, 2, 3, 5, 6, 3, 2, 4 }
for f = 0, 7 do
B[21 + f] = fila[f + 1]
B[31 + f] = 1
for r = 2, 5 do B[21 + f + r * 10] = 0 end
B[81 + f] = -1
B[91 + f] = -fila[f + 1]
end
turno, der, ep, hm, hp, tope = 1, 15, 0, 0, 0, 1
RK[1], RK[-1] = 25, 95
evaluar()
end
function atacado(q, s)
if B[q - 9 * s] == s or B[q - 11 * s] == s then return true end
for i = 1, 8 do
if B[q + NO[i]] == 2 * s or B[q + KO[i]] == 6 * s then return true end
end
for i = 1, 4 do
local o = DO[i]
local t = q + o
local c = B[t]
while c == 0 do t = t + o; c = B[t] end
if c == 3 * s or c == 5 * s then return true end
o = OO[i]
t = q + o
c = B[t]
while c == 0 do t = t + o; c = B[t] end
if c == 4 * s or c == 5 * s then return true end
end
return false
end
function add(f, t, p, c)
local v = 0
if c ~= 0 then v = math.abs(c) * 10 - p end
if p == 1 and (t > 90 or t < 29) then v = v + 80 end
MV[tope] = v * 16384 + f + t * 128
tope = tope + 1
end
function gen(sol)
local s = turno
for f = 21, 98 do
local p = B[f] * s
if p > 0 and p < 7 then
if p == 1 then
local t = f + 10 * s
if not sol and B[t] == 0 then
add(f, t, 1, 0)
if ((s == 1 and f < 39) or (s == -1 and f > 80)) and B[t + 10 * s] == 0 then
add(f, t + 10 * s, 1, 0)
end
end
for k = -1, 1, 2 do
local x = t + k
local c = B[x]
if c ~= 7 and c * s < 0 then
add(f, x, 1, c)
elseif x == ep then
add(f, x, 1, 1)
end
end
else
local of, sl = OF[p], p >= 3 and p <= 5
for i = 1, #of do
local o = of[i]
local t = f + o
local c = B[t]
while c ~= 7 do
if c == 0 then
if not sol then add(f, t, p, 0) end
else
if c * s < 0 then add(f, t, p, c) end
break
end
if not sl then break end
t = t + o
c = B[t]
end
end
if p == 6 and not sol then enroques(f, s) end
end
end
end
end
function enroques(f, s)
local e = (s == 1) and 25 or 95
if f ~= e or atacado(e, -s) then return end
local k, q = (s == 1) and 1 or 4, (s == 1) and 2 or 8
if der & k ~= 0 and B[e + 1] == 0 and B[e + 2] == 0 and not atacado(e + 1, -s) then
add(e, e + 2, 6, 0)
end
if der & q ~= 0 and B[e - 1] == 0 and B[e - 2] == 0 and B[e - 3] == 0
and not atacado(e - 1, -s) then
add(e, e - 2, 6, 0)
end
end
function val(p, q)
local s = (p > 0) and 1 or -1
local t = p * s
local f = q % 10 - 1
local r = q // 10 - 2
if s < 0 then r = 7 - r end
local cf = (f < 4) and f or 7 - f
local cr = (r < 4) and r or 7 - r
local v
if t == 1 then
v = 100 + r * r * 2
if cf == 3 and r >= 2 and r <= 4 then v = v + 12 end
elseif t == 2 then
v = 285 + (cf + cr) * 7
elseif t == 3 then
v = 315 + (cf + cr) * 4
elseif t == 4 then
v = 500 + cf * 2
if r == 6 then v = v + 20 end
elseif t == 5 then
v = 900 + (cf + cr) * 2
elseif FINAL then
v = (cf + cr) * 8
else
v = (r == 0) and 20 or -15 * r
if cf <= 1 then v = v + 15 end
end
if (t == 2 or t == 3) and r == 0 then v = v - 15 end
return v * s
end
function zh(p, q)
local k = ((p + 8) * 128 + q) * 0x9E3779B1
return (k ~ (k >> 15)) & 0x7FFFFFFF
end
function evaluar()
local mat = 0
ev, hh = 0, (turno == 1) and 0 or LADO
for q = 21, 98 do
local p = B[q]
if p ~= 0 and p ~= 7 then
mat = mat + VB[math.abs(p)]
hh = hh ~ zh(p, q)
end
end
FINAL = mat <= 2000
for q = 21, 98 do
local p = B[q]
if p ~= 0 and p ~= 7 then ev = ev + val(p, q) end
end
end
function hacer(m)
local f, t = m % 128, m // 128
local p, c = B[f], B[t]
local h = hp
U[h + 1], U[h + 2], U[h + 3], U[h + 4], U[h + 5], U[h + 6] = c, ep, der, ev, p, hh
hp = h + 6
local s = turno
local ap = p * s
local q = p
local x = hh ~ zh(p, f) ~ LADO
ev = ev - val(p, f)
if c ~= 0 then
ev = ev - val(c, t)
x = x ~ zh(c, t)
end
if ap == 1 then
if t == ep then
local cs = t - 10 * s
ev = ev - val(B[cs], cs)
x = x ~ zh(B[cs], cs)
B[cs] = 0
end
if t > 90 or t < 29 then q = 5 * s end
elseif ap == 6 then
RK[s] = t
if t - f == 2 then
B[f + 1], B[f + 3] = B[f + 3], 0
ev = ev - val(4 * s, f + 3) + val(4 * s, f + 1)
x = x ~ zh(4 * s, f + 3) ~ zh(4 * s, f + 1)
elseif f - t == 2 then
B[f - 1], B[f - 4] = B[f - 4], 0
ev = ev - val(4 * s, f - 4) + val(4 * s, f - 1)
x = x ~ zh(4 * s, f - 4) ~ zh(4 * s, f - 1)
end
end
ep = 0
if ap == 1 and (t - f == 20 or f - t == 20) then ep = (f + t) // 2 end
der = der & (CMT[f] or 15) & (CMT[t] or 15)
B[t], B[f] = q, 0
ev = ev + val(q, t)
hh = x ~ zh(q, t)
turno = -s
end
function deshacer(m)
local f, t = m % 128, m // 128
local h = hp - 6
local c, e, d, v, p = U[h + 1], U[h + 2], U[h + 3], U[h + 4], U[h + 5]
hh = U[h + 6]
hp = h
turno = -turno
local s = turno
B[f], B[t] = p, c
ep, der, ev = e, d, v
local ap = p * s
if ap == 1 and t == e then
B[t - 10 * s] = -s
elseif ap == 6 then
RK[s] = f
if t - f == 2 then
B[f + 3], B[f + 1] = B[f + 1], 0
elseif f - t == 2 then
B[f - 4], B[f - 1] = B[f - 1], 0
end
end
end
function legales()
local s0 = tope
gen(false)
local e, me = tope, turno
nLJ = 0
for i = s0, e - 1 do
local m = MV[i] % 16384
hacer(m)
if not atacado(RK[me], turno) then
nLJ = nLJ + 1
LJ[nLJ] = m
end
deshacer(m)
end
tope = s0
end
function tic()
cnt = cnt + 1
if cnt >= NPF then
cnt = 0
coroutine.yield()
if fr - t0 > TMAX[lvl] then aborta = true end
end
end
function elegir(i, e)
local bj, bv = i, MV[i]
for j = i + 1, e - 1 do
if MV[j] > bv then bj, bv = j, MV[j] end
end
MV[i], MV[bj] = bv, MV[i]
end
function remate()
if ev > -200 and ev < 200 then return 0 end
local s = (ev > 0) and 1 or -1
local w, l = RK[s], RK[-s]
local lf, lr = l % 10 - 1, l // 10 - 2
local df = math.abs(w % 10 - 1 - lf)
local dr = math.abs(w // 10 - 2 - lr)
local cd = math.max(3 - lf, lf - 4) + math.max(3 - lr, lr - 4)
local wf, wr = w % 10 - 1, w // 10 - 2
local wc = (math.min(wf, 7 - wf) + math.min(wr, 7 - wr)) * 8
return s * (cd * 10 + (14 - df - dr) * 6 - wc)
end
function ab(d, a, b, ply)
tic()
if aborta then return 0 end
local me, sol = turno, d <= 0
if sol then
local st = ev
if FINAL then st = st + remate() end
st = st * me
if st >= b then return st end
if st > a then a = st end
if ply >= 10 then return a end
elseif ply > 0 then
PH[ply] = hh
for i = ply - 2, 1, -2 do
if PH[i] == hh then return 0 end
end
for i = nGH, math.max(1, nGH - 30), -1 do
if GH[i] == hh then return 0 end
end
end
local s0 = tope
gen(sol)
local e, n = tope, 0
for i = s0, e - 1 do
elegir(i, e)
local m = MV[i] % 16384
hacer(m)
if not atacado(RK[me], turno) then
n = n + 1
local v = -ab(d - 1, -b, -a, ply + 1)
deshacer(m)
if v >= b then
tope = s0
return v
end
if v > a then a = v end
else
deshacer(m)
end
end
tope = s0
if n == 0 and not sol then
return atacado(RK[me], -me) and ply - MATE or 0
end
return a
end
function pensar()
evaluar()
local n = nLJ
for i = 1, n do RM[i], RS[i] = LJ[i], 0 end
local mejor = RM[1]
if n == 1 then return mejor end
for d = 1, PROF[lvl] do
local a = -INF
for i = 1, n do
local m = RM[i]
hacer(m)
local v = -ab(d - 1, -INF, -a, 1)
deshacer(m)
if aborta then break end
if not FINAL then v = v + flr(rnd(RUIDO[lvl] + 1)) end
RS[i] = v
if v > a then a = v end
end
if aborta then break end
for i = 2, n do
local m, v, j = RM[i], RS[i], i - 1
while j >= 1 and RS[j] < v do
RM[j + 1], RS[j + 1] = RM[j], RS[j]
j = j - 1
end
RM[j + 1], RS[j + 1] = m, v
end
mejor = RM[1]
if RS[1] > MATE - 100 then break end
end
return mejor
end
function nombre(q)
return string.char(96 + q % 10) .. (q // 10 - 1)
end
function sinMaterial()
local n, menor = 0, true
for q = 21, 98 do
local t = math.abs(B[q])
if t ~= 0 and t < 6 then
n = n + 1
if t ~= 2 and t ~= 3 then menor = false end
end
end
return n == 0 or (n == 1 and menor)
end
function empezar()
yo = csel
nueva()
sNiv = "Nivel " .. lvl
sTu, sYo, uf, ut = nil, nil, nil, nil
pdest, parp, jaque = 0, 0, false
nGH, GH[1] = 1, hh
legales()
siguiente()
end
function siguiente()
if turno == yo then
sEst = "Tu turno"
nPZ, ci = lista(PZ), 1
for i = 1, nPZ do
if PZ[i] == pdest then ci = i end
end
estado = "elige"
ayuda()
else
cnt, aborta, t0 = 0, false, fr
for q = 21, 98 do V[q] = B[q] end
hilo = coroutine.create(pensar)
estado = "piensa"
end
end
function mover(m)
local f, t = m % 128, m // 128
local p, c = B[f], B[t]
if p == 1 or p == -1 or c ~= 0 then hm = 0 else hm = hm + 1 end
local txt = nombre(f) .. nombre(t)
local quien = turno
hacer(m)
hp = 0
if hm == 0 then nGH = 0 end
nGH = nGH + 1
GH[nGH] = hh
local veces = 0
for i = 1, nGH do
if GH[i] == hh then veces = veces + 1 end
end
uf, ut = f, t
if quien == yo then
sTu = "Tú " .. txt
pdest = t
else
sYo = "Yo " .. txt
parp = 45
end
legales()
jaque = atacado(RK[turno], -turno)
if nLJ == 0 then
if jaque then
terminar(turno == yo and -1 or 1, "Jaque mate")
else
terminar(0, "Ahogado")
end
elseif hm >= 100 then
terminar(0, "50 jugadas")
elseif veces >= 3 then
terminar(0, "Repetición")
elseif sinMaterial() then
terminar(0, "Sin piezas")
else
siguiente()
end
end
function terminar(res, motivo)
sEst = motivo
sRes = (res > 0) and "¡Ganaste!" or (res < 0) and "Perdiste" or "Tablas"
dset(7 + lvl, (dget(7 + lvl) or 0) + 1)
if res > 0 then dset(3 + lvl, (dget(3 + lvl) or 0) + 1) end
textosMenu()
estado, timer = "fin", 30
end
function casilla(row, col)
if yo == 1 then return 21 + col + (7 - row) * 10 end
return 28 - col + row * 10
end
function pantalla(q)
local f, r = q % 10 - 1, q // 10 - 2
if yo == 1 then return f * 8, (7 - r) * 8 end
return (7 - f) * 8, r * 8
end
function lista(T, o)
local n = 0
for row = 0, 7 do
for col = 0, 7 do
local q = casilla(row, col)
for i = 1, nLJ do
local m = LJ[i]
if (o and m % 128 == o and m // 128 == q) or (not o and m % 128 == q) then
n = n + 1
T[n] = q
break
end
end
end
end
return n
end
function ayuda()
sAyu = (estado == "destino" and DS[di] == sel) and "B: volver" or "A:sig B:ok"
end
function pulsaA()
if btn("a") then
rep = rep + 1
return rep == 1 or (rep > 12 and rep % 4 == 0)
end
rep = 0
return false
end
function textosMenu()
m1 = "Color: " .. ((csel == 1) and "blancas" or "negras")
m2 = "Nivel: " .. lvl
sStat = "Ganadas " .. (dget(3 + lvl) or 0) .. " de " .. (dget(7 + lvl) or 0)
end
function _update()
fr = fr + 1
if parp > 0 then parp = parp - 1 end
if estado == "menu" then
if pulsaA() then mi = mi % 3 + 1 end
if btnp("b") then
if mi == 1 then
csel = -csel
dset(3, (csel == -1) and 1 or 0)
elseif mi == 2 then
lvl = lvl % 4 + 1
dset(2, lvl)
else
empezar()
return
end
textosMenu()
end
elseif estado == "elige" then
if pulsaA() then ci = ci % nPZ + 1 end
if btnp("b") then
sel = PZ[ci]
nDS = lista(DS, sel) + 1
DS[nDS] = sel
di = 1
estado = "destino"
ayuda()
end
elseif estado == "destino" then
if pulsaA() then
di = di % nDS + 1
ayuda()
end
if btnp("b") then
local q = DS[di]
if q == sel then
estado = "elige"
ayuda()
else
for i = 1, nLJ do
local m = LJ[i]
if m % 128 == sel and m // 128 == q then
mover(m)
break
end
end
end
end
elseif estado == "piensa" then
local ok, m = coroutine.resume(hilo)
if not ok then
printh(m)
error(m)
end
if coroutine.status(hilo) == "dead" then
hilo = nil
mover(m)
end
elseif estado == "fin" then
timer = timer - 1
if timer <= 0 and (btnp("a") or btnp("b")) then
estado = "menu"
end
end
end
function esquinas(q)
local x, y = pantalla(q)
line(x, y, x + 2, y)
line(x, y, x, y + 2)
line(x + 7, y + 5, x + 7, y + 7)
line(x + 5, y + 7, x + 7, y + 7)
end
function marca(q)
local x, y = pantalla(q)
rectfill(x, y, x + 7, y + 7, 2)
end
function tablero()
for row = 0, 7 do
for col = 0, 7 do
local x, y = col * 8, row * 8
if (row + col) % 2 == 1 then
for yy = 0, 6, 2 do
for xx = 0, 6, 2 do pset(x + xx, y + yy) end
end
end
local p = ((estado == "piensa") and V or B)[casilla(row, col)]
if p ~= 0 then
local s = SIL[math.abs(p)]
spr(s, x - 1, y, 0)
spr(s, x + 1, y, 0)
spr(s, x, y - 1, 0)
spr(s, x, y + 1, 0)
spr(s, x, y, 1)
if p < 0 then spr(s, x + 1, y, 2) end
end
end
end
if uf then
esquinas(uf)
esquinas(ut)
if parp > 0 and flr(parp / 6) % 2 == 0 then marca(ut) end
end
if estado == "elige" then
marca(PZ[ci])
elseif estado == "destino" then
local x, y = pantalla(sel)
rect(x, y, x + 7, y + 7, 2)
for i = 1, nDS - 1 do
x, y = pantalla(DS[i])
rectfill(x + 3, y + 3, x + 4, y + 4, 2)
end
marca(DS[di])
end
end
function _draw()
cls()
if estado == "menu" then
print("AJEDREZ", 22, 2, 1, 2)
print(m1, 28, 22)
print(m2, 28, 31)
print("Jugar", 28, 40)
print(">", 20, 13 + mi * 9)
print(sStat, 20, 55)
return
end
tablero()
local x = 67
print(sNiv, x, 0)
if estado == "piensa" then
print("Pienso", x, 10)
rect(x, 55, x + 58, 59)
local w = flr(57 * math.min(1, (fr - t0) / TMAX[lvl]))
if w > 0 then rectfill(x + 1, 56, x + w, 58) end
else
print(sEst, x, 10)
end
if estado == "fin" then
print(sRes, x, 19)
if flr(fr / 15) % 2 == 0 then print("Pulsa", x, 55) end
else
if jaque then print("¡Jaque!", x, 19) end
if estado == "elige" or estado == "destino" then print(sAyu, x, 55) end
end
if sTu then print(sTu, x, 31) end
if sYo then print(sYo, x, 40) end
end
