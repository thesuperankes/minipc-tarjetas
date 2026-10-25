-- DEMO
-- Seis efectos de la demoscene en 16 KB. Cada efecto se calcula a
-- 64 x 32 y se muestra a 128 x 64: cada punto se vuelve un bloque de
-- 2 x 2 tramado con una matriz de Bayer, así se ven 17 tonos de gris
-- con un solo bit. Todo con enteros y un solo blit por cuadro.
--
--   A: siguiente parte.   B: muestra los milisegundos por cuadro.
--
-- La pantalla son 256 enteros (W[1] a W[256]), 4 por fila, de arriba
-- abajo, y el bit 31 es el píxel de la izquierda.
-- Ojo: en Lua, >> no sirve para dividir números negativos (los vuelve
-- enormes); para eso se usa //. Si tu blit los ordena
-- de otra forma, solo hay que cambiar empaquetar().

DUR = 270                -- cuadros por parte (9 s)
M   = 0xFFFFFFFF         -- en el aparato vale -1 y no hace nada

-- (las mayúsculas con tilde no existen en la letra del aparato)
NOMBRES = { "PLASMA", "TUNEL", "ROTOZOOM", "VECTORES", "MOIRE", "FUEGO" }
TEXTO = "   HOLA DESDE UN ESP32-C3 DE 160 MHZ CON 400 KB Y UNA PANTALLA DE"
  .. " 1 BIT ... TODO ESTO CABE EN 16 KB DE LUA ... GRACIAS POR MIRAR ..."
  .. " SALUDOS A LA DEMOSCENE ...     "

-- Cubo: vértices y aristas
VX = { -1, -1, -1,  1, -1, -1,  1, 1, -1,  -1, 1, -1,
       -1, -1,  1,  1, -1,  1,  1, 1,  1,  -1, 1,  1 }
ED = { 1, 2, 2, 3, 3, 4, 4, 1, 5, 6, 6, 7, 7, 8, 8, 5, 1, 5, 2, 6, 3, 7, 4, 8 }

function _init()
  W, F = {}, {}
  for i = 1, 256 do W[i] = 0 end
  -- 64 x 32 tonos: justo 2048, porque Lua reserva las listas en
  -- potencias de dos y 2049 casillas ocuparían el doble
  for i = 1, 2048 do F[i] = 0 end

  -- seno entero de 256 pasos, de -127 a 127
  SN = {}
  for i = 0, 255 do SN[i] = flr(math.sin(i * math.pi / 128) * 127 + 0.5) end

  -- paleta triangular: 0 sube a 16 y baja, en 32 pasos
  PAL = {}
  for k = 0, 31 do PAL[k] = (k <= 16) and k or 32 - k end

  -- Bayer 4x4. Para cada paridad del punto (columna, fila) hay dos
  -- tablas que dicen qué bits del bloque 2x2 encender según el tono:
  -- una para la fila de arriba y otra para la de abajo.
  local B = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 }
  BT = {}
  for py = 0, 1 do
    for px = 0, 1 do
      local ta, tb = {}, {}
      for v = 0, 16 do
        local function on(i, j)
          return (v > B[(2 * py + j) * 4 + 2 * px + i + 1]) and 1 or 0
        end
        ta[v] = on(0, 0) * 2 + on(1, 0)
        tb[v] = on(0, 1) * 2 + on(1, 1)
      end
      BT[py * 4 + px * 2 + 1], BT[py * 4 + px * 2 + 2] = ta, tb
    end
  end

  -- túnel: un cuarto de pantalla (32 x 16), los otros tres salen por
  -- simetría. Cada entero guarda profundidad (bits 0-6), niebla (8-12)
  -- y ángulo (16-21).
  TQ = {}
  for qy = 0, 15 do
    for qx = 0, 31 do
      local dx, dy = qx + 0.5, qy + 0.5
      local d = math.sqrt(dx * dx + dy * dy)
      local j = qy * 32 + qx + 1
      local ang = flr(math.atan(dy, dx) * 64 / math.pi)     -- 0 a 32
      local fog = math.min(16, flr(d * 0.55))
      TQ[j] = (flr(700 / d) & 127) | (fog << 8) | (ang << 16)
    end
  end

  -- textura de 16 x 16 para el rotozoom: rombo con degradado y tablero
  TX = {}
  for y = 0, 15 do
    for x = 0, 15 do
      local r = math.abs(x - 7.5) + math.abs(y - 7.5)
      local v = (r < 7) and flr(16 - r * 2) or ((((x >> 2) ~ (y >> 2)) & 1) * 5)
      TX[y * 16 + x] = mid(0, v, 16)
    end
  end

  -- auxiliares
  CA, RB, DG = {}, {}, {}
  PX, PY = {}, {}
  SX, SY, SZ = {}, {}, {}
  semilla = 12345
  for k = 1, 40 do estrella(k) SZ[k] = 1 + azar() % 64 end
  CH = {}
  for c in TEXTO:gmatch("[%z\1-\127\194-\244][\128-\191]*") do CH[#CH + 1] = c end

  medir, ult, dt = false, ms(), 33
  inicio()
end

function azar()   -- generador congruencial: más barato que rnd()
  semilla = (semilla * 1103515245 + 12345) & 0x7FFFFFFF
  return semilla >> 8
end

function estrella(k)
  SX[k] = azar() % 512 - 256
  SY[k] = azar() % 256 - 128
  SZ[k] = 64
end

-- Secuencia ------------------------------------------------------------

function inicio()
  parte, t, cuadros, t0 = 0, 0, 0, ms()
end

function siguiente()
  parte, t = parte + 1, 0
  if parte == 1 then cuadros, t0 = 0, ms() end
  if parte > 6 then
    local seg = (ms() - t0) / 1000
    fps = string.format("%.1f fps reales", cuadros / math.max(seg, 0.001))
  end
end

function _update()
  local ahora = ms()
  dt, ult = ahora - ult, ahora
  t = t + 1
  if btnp("b") then medir = not medir end

  if parte == 0 then
    if t > 165 or btnp("a") then siguiente() end
  elseif parte <= 6 then
    cuadros = cuadros + 1
    if t >= DUR or btnp("a") then siguiente() end
  elseif t > 30 and btnp("a") then
    inicio()
  end
end

-- Empaquetado: de F (64 x 32 tonos de 0 a 16) a W (128 x 64 bits) ------

function empaquetar()
  local F, W = F, W
  local i, w = 1, 1
  for ly = 0, 31 do
    local b = (ly & 1) * 4
    local ea, eb, oa, ob = BT[b + 1], BT[b + 2], BT[b + 3], BT[b + 4]
    for k = 0, 3 do
      local top, bot = 0, 0
      for j = 1, 8 do
        local v = F[i]
        top = (top << 2) | ea[v]
        bot = (bot << 2) | eb[v]
        v = F[i + 1]
        top = (top << 2) | oa[v]
        bot = (bot << 2) | ob[v]
        i = i + 2
      end
      W[w + k], W[w + 4 + k] = top, bot
    end
    w = w + 8
  end
  blit(W)
end

-- Efectos --------------------------------------------------------------

function plasma()
  local SN, F, PAL, CA, RB, DG = SN, F, PAL, CA, RB, DG
  for x = 0, 63 do
    CA[x] = SN[(x * 5 + t * 3) & 255] + SN[(x * 2 - t) & 255] + 256
  end
  for y = 0, 31 do RB[y] = SN[(y * 7 - t * 2) & 255] + 128 + t * 8 end
  for d = 0, 94 do DG[d] = SN[(d * 3 + t * 4) & 255] + 128 end
  local i = 1
  for y = 0, 31 do
    local r = RB[y]
    for x = 0, 63 do
      F[i] = PAL[((CA[x] + r + DG[x + y]) >> 4) & 31]
      i = i + 1
    end
  end
end

-- Cada punto mira su ángulo y profundidad, les suma el giro y el avance,
-- y el bit 4 de la mezcla decide el cuadro del tablero. La niebla
-- oscurece el centro, que es lo más lejano.
function tunel()
  local TQ, F = TQ, F
  local ta = (t * 2 + (SN[(t * 2) & 255] // 4)) & 127
  local td = (t * 3) & 127
  local i = 1
  for y = 0, 31 do
    local up = y < 16
    local j0 = (up and (15 - y) or (y - 16)) * 32 + 1
    local s = up and 1 or -1
    local bl = 64 + ta                     -- mitad izquierda: 64 ± a
    local br = (up and 128 or 0) + ta      -- mitad derecha: 128 - a o a
    for x = 31, 0, -1 do
      local e = TQ[j0 + x]
      F[i] = ((e >> 8) & 31) >> ((((bl + s * (e >> 16)) ~ (e + td)) >> 3) & 2)
      i = i + 1
    end
    for x = 0, 31 do
      local e = TQ[j0 + x]
      F[i] = ((e >> 8) & 31) >> ((((br - s * (e >> 16)) ~ (e + td)) >> 3) & 2)
      i = i + 1
    end
  end
end

function rotozoom()
  local TX, F = TX, F
  local a = (t * 2) & 255
  local z = 110 + SN[(t * 3) & 255] * 80 // 128   -- zoom en punto fijo 8.8
  local du = SN[(a + 64) & 255] * z // 128
  local dv = SN[a] * z // 128
  local u0 = t * 40 - 32 * du + 16 * dv
  local v0 = t * 25 - 32 * dv - 16 * du
  local i = 1
  for y = 0, 31 do
    local u, v = u0, v0
    for x = 0, 63 do
      F[i] = TX[((u >> 8) & 15) | ((v >> 4) & 240)]
      u, v = u + du, v + dv
      i = i + 1
    end
    u0, v0 = u0 - dv, v0 + du
  end
end

-- Dos centros que se mueven; cada punto mezcla con XOR el cuadrado de
-- su distancia a ambos. Las distancias se llevan sumando, sin multiplicar.
function moire()
  local F, PAL = F, PAL
  local ax = 32 + (SN[(t * 2) & 255] * 26 // 128)
  local ay = 16 + (SN[(t * 3 + 40) & 255] * 13 // 128)
  local bx = 32 + (SN[(t * 3 + 128) & 255] * 26 // 128)
  local by = 16 + (SN[(t * 2 + 90) & 255] * 13 // 128)
  local sh = 5 + ((t >> 7) & 1)          -- grosor de los anillos
  local i = 1
  for y = 0, 31 do
    local s1 = ax * ax + (y - ay) * (y - ay)
    local s2 = bx * bx + (y - by) * (y - by)
    local e1, e2 = 1 - 2 * ax, 1 - 2 * bx
    for x = 0, 63 do
      F[i] = PAL[((s1 ~ s2) >> sh) & 31]
      s1, s2 = s1 + e1, s2 + e2
      e1, e2 = e1 + 2, e2 + 2
      i = i + 1
    end
  end
end

function fuego()
  local F = F
  -- la última fila son las brasas: focos al azar que cambian
  for i = 1985, 2048 do
    local r = azar()
    F[i] = (r & 3 ~= 0) and 16 or (r & 4) * 2
  end
  -- cada punto es el promedio de los de abajo, con un poco de pérdida
  for i = 1, 1920 do
    local s = F[i + 63] + F[i + 64] + F[i + 65] + F[i + 128]
    F[i] = (s > 1) and ((s - 1) >> 2) or 0
  end
  for i = 1921, 1984 do                    -- justo sobre las brasas
    local s = F[i + 63] + F[i + 64] * 3
    F[i] = (s > 1) and ((s - 1) >> 2) or 0
  end
end

function vectores()
  cls()
  -- estrellas
  for k = 1, 40 do
    local z = SZ[k] - 1
    if z < 1 then estrella(k) z = 64 end
    SZ[k] = z
    local x, y = 64 + SX[k] * 4 // z, 32 + SY[k] * 4 // z
    if x < 0 or x > 127 or y < 0 or y > 63 then
      estrella(k)
    else
      pset(x, y)
      if z < 20 then pset(x + 1, y) end
    end
  end
  -- cubo girando en dos ejes, con el tamaño latiendo
  local a, b = (t * 3) & 255, (t * 2) & 255
  local ca, sa = SN[(a + 64) & 255], SN[a]
  local cb, sb = SN[(b + 64) & 255], SN[b]
  local r = 17 + SN[(t * 6) & 255] // 32
  for k = 0, 7 do
    local x, y, z = VX[k * 3 + 1] * r, VX[k * 3 + 2] * r, VX[k * 3 + 3] * r
    x, z = (x * ca - z * sa) // 128, (x * sa + z * ca) // 128
    y, z = (y * cb - z * sb) // 128, (y * sb + z * cb) // 128
    PX[k + 1] = 64 + x * 80 // (z + 90)
    PY[k + 1] = 22 + y * 80 // (z + 90)
  end
  for e = 1, 24, 2 do
    local p, q = ED[e], ED[e + 1]
    line(PX[p], PY[p], PX[q], PY[q])
  end
  -- texto ondulante
  local off = t * 2
  local c0 = off // 12
  for k = 0, 11 do
    local c = CH[(c0 + k) % #CH + 1]
    local x = k * 12 - off % 12
    print(c, x, 46 + SN[(x * 3 + t * 6) & 255] // 32, 1, 2)
  end
end

-- Dibujo ---------------------------------------------------------------

function etiqueta()
  if t < 45 then
    local s = NOMBRES[parte]
    local w = utf8.len(s) * 6 + 2
    rectfill(0, 0, w, 9, 0)
    print(s, 2, 1)
  end
  if t < 3 then rectfill(0, 0, 127, 63, 2) end   -- destello al cambiar
end

function intro()
  cls()
  local L = { "ESP32-C3 a 160 MHz", "128 x 64 - 1 bit", "16 KB de Lua" }
  for k = 1, 3 do
    local n = mid(0, (t - (k - 1) * 30) // 2, 99)
    if n > 0 then print(L[k]:sub(1, n), 4, (k - 1) * 10 + 2) end
  end
  if t > 100 then
    print("DEMO", 16, 34, 1, 4)
    if t < 106 then rectfill(0, 0, 127, 63, 2) end
  end
end

function final()
  cls()
  print("FIN", 46, 4, 1, 3)
  print(fps, 64 - #fps * 3, 32)
  if t > 30 and t % 30 < 20 then print("A: otra vez", 31, 50) end
end

function _draw()
  if parte == 0 then
    intro()
  elseif parte == 1 then plasma() empaquetar() etiqueta()
  elseif parte == 2 then tunel() empaquetar() etiqueta()
  elseif parte == 3 then rotozoom() empaquetar() etiqueta()
  elseif parte == 4 then vectores() etiqueta()
  elseif parte == 5 then moire() empaquetar() etiqueta()
  elseif parte == 6 then fuego() empaquetar() etiqueta()
  else
    final()
  end

  if medir then
    local s = dt .. " ms"
    rectfill(127 - #s * 6 - 2, 54, 127, 63, 0)
    print(s, 127 - #s * 6, 56)
  end
end
