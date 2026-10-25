-- PINBALL
-- A mueve la aleta izquierda, B la derecha. Basta con tocarlos:
-- la aleta sube al pulsar y baja sola al medio segundo, así nunca
-- hace falta mantener los dos botones a la vez.
-- La mesa mide tres pantallas de alto; la cámara sigue a la bola y el
-- minimapa de la derecha muestra la mesa completa.
--
-- Bumpers: 100. Slingshots: 10. Dianas: 200; las tres suben el
-- multiplicador. Carriles de arriba: 50; los tres dan un bono.
-- Las aletas rotan las luces de los carriles. Bola extra cada 25 000.

OX, TH = 2, 192           -- desplazamiento en pantalla y alto de la mesa
G     = 0.06              -- gravedad: la inclinación de la mesa
R     = 2                 -- radio de la bola
VMAX  = 6                 -- velocidad máxima
SUB   = 4                 -- subpasos de física por cuadro
FL    = 12                -- largo de las aletas
FREP, FUP = 0.5, -0.45    -- ángulos de reposo y arriba
FMAX  = 15                -- cuadros que una aleta puede quedar arriba

-- Paredes: x1, y1, x2, y2 seguidos
WL = {
  74, 191, 74, 14,   74, 14, 68, 6,   68, 6, 56, 2,   56, 2, 20, 2,
  20, 2, 8, 6,       8, 6, 1, 14,     1, 14, 1, 154,  1, 154, 19, 176,
  68, 191, 68, 40,   68, 154, 50, 176, 68, 189, 74, 189,
  16, 14, 16, 22,    30, 14, 30, 22,  44, 14, 44, 22, 58, 14, 58, 22,
  19, 176, 19, 196,  50, 176, 50, 196,   -- bajo los ejes de las aletas
  8, 132, 8, 150,    8, 150, 17, 159,
  61, 132, 61, 150,  61, 150, 52, 159,
}
SL = { 8, 132, 17, 159,   61, 132, 52, 159 }          -- slingshots
TG = { 26, 100, 30, 100,  32, 100, 36, 100,  38, 100, 42, 100 } -- dianas
BP = { 22, 50, 46, 50, 34, 70 }                       -- bumpers
LC = { 23, 37, 51 }                                   -- centros de carriles

-- Casilla guardada: 0 = récord

function _init()
  TA, RL, BF = {}, {}, { 0, 0, 0 }
  fr = 0
  rec = dget(0) or 0
  rtxt = "Récord " .. rec
  estado = "menu"
end

-- Partida ------------------------------------------------------------

function empezar()
  score, mult, bolas, extra = 0, 1, 3, 25000
  stxt, mtxt, fuerza = "0", "x1", 0
  for i = 1, 3 do TA[i], RL[i] = true, false end
  la, ra, lw, rw, hla, hra = FREP, FREP, 0, 0, 0, 0
  cy, msgt = TH - 64, 0
  nueva = true
  lanzar()
end

function lanzar()
  bx, by, vx, vy = 71, 185, 0, 0
  estado = "lanzar"
end

function aviso(s)
  msg, msgt = s, 60
end

function pts(n)
  score = score + n * mult
  stxt = tostring(score)
  if score >= extra then
    extra = extra + 25000
    bolas = bolas + 1
    aviso("BOLA+")
  end
end

-- Física -------------------------------------------------------------

-- Choque con un segmento. Devuelve true si la bola venía hacia él.
function pared(x1, y1, x2, y2, e, kick)
  local dx, dy = x2 - x1, y2 - y1
  local t = ((bx - x1) * dx + (by - y1) * dy) / (dx * dx + dy * dy)
  t = mid(0, t, 1)
  local px, py = x1 + dx * t, y1 + dy * t
  local nx, ny = bx - px, by - py
  local d2 = nx * nx + ny * ny
  if d2 >= R * R or d2 == 0 then return false end
  local d = math.sqrt(d2)
  nx, ny = nx / d, ny / d
  bx, by = px + nx * R, py + ny * R
  local vn = vx * nx + vy * ny
  if vn >= 0 then return false end
  vx, vy = vx - (1 + e) * vn * nx, vy - (1 + e) * vn * ny
  if kick > 0 then vx, vy = vx + nx * kick, vy + ny * kick end
  return vn < -0.3
end

-- Choque con una aleta: un segmento que gira. Su superficie empuja
-- la bola con la velocidad que tenga en el punto de contacto.
function aleta(px, py, a, w, sd)
  local dx, dy = sd * math.cos(a) * FL, math.sin(a) * FL
  local t = ((bx - px) * dx + (by - py) * dy) / (FL * FL)
  -- detrás del eje manda la rampa lateral; sin esto la bola se traba ahí
  if t < 0.05 then return end
  t = math.min(t, 1)
  local qx, qy = px + dx * t, py + dy * t
  local nx, ny = bx - qx, by - qy
  local d2 = nx * nx + ny * ny
  local rr = R + 1.5
  if d2 >= rr * rr or d2 == 0 then return end
  local d = math.sqrt(d2)
  nx, ny = nx / d, ny / d
  bx, by = qx + nx * rr, qy + ny * rr
  local rx, ry = qx - px, qy - py
  local sx, sy = -ry * w * sd, rx * w * sd
  local vn = (vx - sx) * nx + (vy - sy) * ny
  if vn < 0 then
    vx, vy = vx - 1.3 * vn * nx, vy - 1.3 * vn * ny
  end
end

function bumper(i)
  local cx, cy2 = BP[i * 2 - 1], BP[i * 2]
  local nx, ny = bx - cx, by - cy2
  local d2 = nx * nx + ny * ny
  local rr = R + 5
  if d2 >= rr * rr or d2 == 0 then return end
  local d = math.sqrt(d2)
  nx, ny = nx / d, ny / d
  bx, by = cx + nx * rr, cy2 + ny * rr
  local vn = vx * nx + vy * ny
  if vn < 0 then
    vx, vy = vx - 2 * vn * nx + nx * 1.8, vy - 2 * vn * ny + ny * 1.8
    BF[i] = 6
    pts(100)
  end
end

function paso()
  local py0 = by
  vy = vy + G / SUB
  bx, by = bx + vx / SUB, by + vy / SUB
  la, ra = la + lw / SUB, ra + rw / SUB

  for i = 1, #WL, 4 do
    pared(WL[i], WL[i + 1], WL[i + 2], WL[i + 3], 0.5, 0)
  end
  for i = 1, #SL, 4 do
    if pared(SL[i], SL[i + 1], SL[i + 2], SL[i + 3], 0.5, 1.5) then pts(10) end
  end
  for k = 1, 3 do
    local i = k * 4 - 3
    if TA[k] and pared(TG[i], TG[i + 1], TG[i + 2], TG[i + 3], 0.4, 0) then
      TA[k] = false
      pts(200)
      if not (TA[1] or TA[2] or TA[3]) then
        TA[1], TA[2], TA[3] = true, true, true
        if mult < 5 then mult = mult + 1 end
        mtxt = "x" .. mult
        pts(1000)
        aviso(mtxt)
      end
    end
  end
  for i = 1, 3 do bumper(i) end
  aleta(19, 176, la, lw, 1)
  aleta(50, 176, ra, rw, -1)

  -- carriles de arriba: se encienden al cruzarlos hacia abajo
  if py0 < 22 and by >= 22 then
    for k = 1, 3 do
      if bx > LC[k] - 7 and bx < LC[k] + 7 and not RL[k] then
        RL[k] = true
        pts(50)
      end
    end
    if RL[1] and RL[2] and RL[3] then
      RL[1], RL[2], RL[3] = false, false, false
      pts(500)
      aviso("BONO")
    end
  end
end

-- Aletas: suben rápido, bajan más lento, y no se quedan arriba más
-- de FMAX cuadros aunque mantengas el botón.
function aletas()
  local a, b = btn("a"), btn("b")
  hla = a and hla + 1 or 0
  hra = b and hra + 1 or 0
  local tl = (a and hla <= FMAX) and FUP or FREP
  local tr = (b and hra <= FMAX) and FUP or FREP
  lw = mid(-0.35, tl - la, 0.15)
  rw = mid(-0.35, tr - ra, 0.15)
  -- las aletas también rotan las luces de los carriles
  if btnp("a") then RL[1], RL[2], RL[3] = RL[2], RL[3], RL[1] end
  if btnp("b") then RL[1], RL[2], RL[3] = RL[3], RL[1], RL[2] end
end

function jugar()
  aletas()
  for s = 1, SUB do paso() end

  local v2 = vx * vx + vy * vy
  if v2 > VMAX * VMAX then
    local k = VMAX / math.sqrt(v2)
    vx, vy = vx * k, vy * k
  end

  if salva > 0 then salva = salva - 1 end

  -- la bola volvió al lanzador
  if bx > 68 and by > 180 and vy * vy < 0.25 then
    lanzar()
    return
  end

  -- bola atascada: una sacudida
  if v2 < 0.01 then quieto = quieto + 1 else quieto = 0 end
  if quieto > 60 then
    vx, vy, quieto = rnd(2) - 1, -2, 0
    aviso("Empujón")
  end

  if by > TH + 4 then
    if salva > 0 then
      aviso("Salvada")
      nueva = false
      lanzar()
    else
      bolas = bolas - 1
      if bolas <= 0 then
        fin()
      else
        aviso("Perdida")
        estado, timer = "perdida", 40
      end
    end
  end
end

function fin()
  nuevo = score > rec
  if nuevo then
    rec = score
    dset(0, rec)
    rtxt = "Récord " .. rec
  end
  estado, timer = "fin", 45
end

function _update()
  fr = fr + 1
  for i = 1, 3 do
    if BF[i] > 0 then BF[i] = BF[i] - 1 end
  end
  if msgt and msgt > 0 then msgt = msgt - 1 end

  if estado == "menu" then
    if btnp("a") or btnp("b") then empezar() end
    return
  end

  if estado == "lanzar" then
    -- la fuerza sube y baja sola; se lanza con cualquier botón
    fuerza = (1 - math.cos(fr * 0.12)) / 2
    aletas()
    la, ra = la + lw, ra + rw
    if btnp("a") or btnp("b") then
      vy, quieto = -(3.5 + 2.5 * fuerza), 0
      if nueva then salva = 150 else salva = 0 end
      nueva = true
      estado = "juego"
    end
  elseif estado == "juego" then
    jugar()
  elseif estado == "perdida" then
    timer = timer - 1
    if timer <= 0 then
      nueva = true
      lanzar()
    end
  elseif estado == "fin" then
    timer = timer - 1
    if timer <= 0 and (btnp("a") or btnp("b")) then estado = "menu" end
    return
  end

  -- la cámara sigue a la bola con suavidad
  local obj = mid(0, by - 30, TH - 64)
  cy = cy + (obj - cy) * 0.3
end

-- Dibujo -------------------------------------------------------------

function seg(x1, y1, x2, y2)
  line(x1 + OX, y1 - cyi, x2 + OX, y2 - cyi)
end

function dibAleta(px, py, a, sd)
  local tx, ty = px + sd * math.cos(a) * FL, py + math.sin(a) * FL
  for k = -1, 1 do seg(px, py + k, tx, ty + k) end
  circfill(px + OX, py - cyi, 2)
end

function mesa()
  for i = 1, #WL, 4 do seg(WL[i], WL[i + 1], WL[i + 2], WL[i + 3]) end
  for i = 1, #SL, 4 do
    seg(SL[i], SL[i + 1], SL[i + 2], SL[i + 3])
    seg(SL[i] + 1, SL[i + 1] + 2, SL[i + 2], SL[i + 3] - 1)
  end
  for k = 1, 3 do
    if TA[k] then
      local i = k * 4 - 3
      rectfill(TG[i] + OX, TG[i + 1] - cyi, TG[i + 2] + OX, TG[i + 3] + 1 - cyi)
    end
  end
  for i = 1, 3 do
    local x, y = BP[i * 2 - 1] + OX, BP[i * 2] - cyi
    if BF[i] > 0 then
      circfill(x, y, 5)
    else
      circ(x, y, 5)
      circ(x, y, 2)
    end
  end
  for k = 1, 3 do
    local x, y = LC[k] + OX - 2, 26 - cyi
    if RL[k] then rectfill(x, y, x + 3, y + 3) else rect(x, y, x + 3, y + 3) end
  end
  dibAleta(19, 176, la, 1)
  dibAleta(50, 176, ra, -1)
  circfill(bx + OX, by - cyi, R)
end

function minimapa()
  local mx, my = 82, 15
  for i = 1, #WL, 4 do
    line(mx + WL[i] / 4, my + WL[i + 1] / 4, mx + WL[i + 2] / 4, my + WL[i + 3] / 4)
  end
  for i = 1, 3 do pset(mx + BP[i * 2 - 1] / 4, my + BP[i * 2] / 4) end
  rect(mx - 1, my + cyi / 4, mx + 19, my + (cyi + 63) / 4, 2)
  if fr % 8 < 6 then pset(mx + bx / 4, my + by / 4, 2) end
end

function _draw()
  cls()

  if estado == "menu" then
    print("PINBALL", 22, 4, 1, 2)
    print("A: aleta izq.", 25, 26)
    print("B: aleta der.", 25, 35)
    print(rtxt, 25, 46)
    if fr % 30 < 20 then print("Pulsa para jugar", 16, 56) end
    return
  end

  cyi = flr(cy)
  mesa()

  line(79, 0, 79, 63)
  print(stxt, 82, 0)
  if msgt > 0 then
    print(msg, 82, 7)
  elseif estado == "lanzar" then
    print("¡Lanza!", 82, 7)
  end
  minimapa()
  print(mtxt, 106, 16)
  for i = 1, math.min(bolas - 1, 3) do circfill(104 + i * 6, 29, 2) end
  if estado == "lanzar" then
    rect(106, 38, 112, 62)
    local h = flr(22 * fuerza)
    if h > 0 then rectfill(107, 61 - h, 111, 61) end
  end

  if estado == "fin" then
    rectfill(8, 14, 70, 48, 0)
    rect(8, 14, 70, 48)
    print("FIN", 30, 17, 1, 2)
    print(stxt, 39 - #stxt * 3, 33)
    if nuevo then print("¡Récord!", 15, 41) end
  end
end
