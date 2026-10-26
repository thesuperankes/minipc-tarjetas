-- MEDIDOR
-- Mide con ms() cuánto tarda cada cosa en el aparato. Corre cada prueba
-- 3 veces, se queda con la más rápida y muestra los resultados.
-- A: cambia de página. B: repite las pruebas.
-- También los escribe en el monitor serie con printh.

N = 20000

-- instrucciones de Lua por vuelta de cada bucle (contadas en Lua 5.4)
PRUEBAS = {
  { "vacio",   "for vacío",          1 },
  { "suma",    "suma de enteros",    2 },
  { "lista",   "leer lista",         5 },
  { "escribe", "escribir lista",     4 },
  { "bits",    "<< >> ~ &",          5 },
  { "global",  "leer global",        3 },
  { "llamada", "llamar función",     6 },
  { "decimal", "decimales",          2 },
  { "seno",    "math.sin",           5 },
}

function _init()
  T, W, W2 = {}, {}, {}
  for i = 1, 2048 do T[i] = i & 15 end
  for i = 1, 256 do W[i] = 0x55555555 W2[i] = ~0x55555555 end
  G = 3
  correr()
end

function correr()
  res, paso, ronda = {}, 1, 1
  pag, estado = 1, "midiendo"
  cuadros, t0f = 0, 0
end

local function f(x) return x end

-- cada prueba devuelve los ms que tardó
local B = {}
function B.vacio() local a = ms() for i = 1, N do end return ms() - a end
function B.suma() local s, a = 0, ms() for i = 1, N do s = s + i end return ms() - a end
function B.lista() local T, s, a = T, 0, ms() for i = 1, N do s = s + T[(i & 2047) + 1] end return ms() - a end
function B.escribe() local T, a = T, ms() for i = 1, N do T[(i & 2047) + 1] = i end return ms() - a end
function B.bits() local s, a = 1, ms() for i = 1, N do s = ((s << 1) ~ (i >> 2)) & 0xFFFF end return ms() - a end
function B.global() local s, a = 0, ms() for i = 1, N do s = s + G end return ms() - a end
function B.llamada() local s, a = 0, ms() for i = 1, N do s = f(i) end return ms() - a end
function B.decimal() local x, a = 0.5, ms() for i = 1, N do x = x * 1.0001 end return ms() - a end
function B.seno() local s, a, sin = 0, ms(), math.sin for i = 1, N do s = sin(i) end return ms() - a end

-- pruebas de dibujo: 20 llamadas cada una
D = {
  { "blit", function() for k = 1, 20 do blit(W) end end },
  { "cls", function() for k = 1, 20 do cls() end end },
  { "line x20", function() for k = 1, 20 do for j = 0, 19 do line(0, j, 127, 63 - j) end end end },
  { "rectfill", function() for k = 1, 20 do rectfill(0, 0, 127, 63, 2) end end },
  { "print", function() for k = 1, 20 do print("HOLA MUNDO 1234567890", 0, 20) end end },
}

function _update()
  if estado == "midiendo" then
    if paso <= #PRUEBAS then
      local p = PRUEBAS[paso]
      local m = B[p[1]]()
      if ronda == 1 or m < res[paso] then res[paso] = m end
    elseif paso <= #PRUEBAS + #D then
      local k = paso - #PRUEBAS
      local a = ms()
      D[k][2]()
      local m = (ms() - a) / 20
      if ronda == 1 or m < res[paso] then res[paso] = m end
    end
    paso = paso + 1
    if paso > #PRUEBAS + #D then
      paso, ronda = 1, ronda + 1
      if ronda > 3 then
        estado, cuadros = "pantalla", 0
      end
    end
  elseif estado == "pantalla" then
    -- 60 cuadros con la pantalla entera cambiando y 60 sin cambios
    if cuadros == 0 or cuadros == 60 then t0f = ms() end
    cuadros = cuadros + 1
    if cuadros == 60 then cambia = (ms() - t0f) / 59 end
    if cuadros == 120 then
      quieta = (ms() - t0f) / 59
      estado = "listo"
      textos()
    end
  else
    if btnp("a") then pag = pag % 3 + 1 end
    if btnp("b") then correr() end
  end
end

function textos()
  L = { "prueba   ms  instr/s" }
  for i, p in ipairs(PRUEBAS) do
    local ms_ = math.max(res[i], 0.5)
    local kps = flr(N * p[3] / ms_)          -- instrucciones por ms
    L[#L + 1] = string.format("%-7s%4dms %5dk", p[1], res[i], kps)
  end
  L[#L + 1] = "Por llamada:"
  for k, d in ipairs(D) do
    L[#L + 1] = string.format("%-8s %5.1f ms", d[1], res[#PRUEBAS + k])
  end
  L[#L + 1] = string.format("cuadro cambia %4.1f ms", cambia)
  L[#L + 1] = string.format("cuadro quieto %4.1f ms", quieta)
  L[#L + 1] = "A: página  B: repetir"
  for i = 1, #L do printh(L[i]) end
end

function _draw()
  if estado == "midiendo" then
    cls()
    print("Midiendo...", 0, 0)
    print("ronda " .. ronda .. " de 3", 0, 10)
    print("prueba " .. paso, 0, 20)
  elseif estado == "pantalla" then
    if cuadros < 60 then
      blit((cuadros % 2 == 0) and W or W2)   -- todo cambia en cada cuadro
    else
      blit(W)                                 -- nada cambia
    end
  else
    cls()
    local i0 = (pag - 1) * 8
    for i = 1, 8 do
      local s = L[i0 + i]
      if s then print(s, 0, (i - 1) * 8) end
    end
  end
end
