{--------------------------------------------------------
 Модуль с функциями элементарных электротехнических
 расчётов.
---------------------------------------------------------}
{$mode objfpc}{$H+}
Unit eltech;

interface

Const
  // Удельное сопротивление при 20 гр. Ц, материал проводника, (Ом * мм^2)/м
  cuprum	= 0.0175;	// Медь
  aluminium	= 0.0281;	// Алюминий
  gold		= 0.023;
  argentum	= 0.015;

// Температурный коэффициент проводников, %/гр C
  cteCuprum	= 0.39;
  cteAluminium	= 0.49;
  cteGold	= 0.37;
  cteArgentum	= 0.38;

// Константы, которые могут понадобится при расчётах
  Pi		= 3.141592653589793;
  TwoPi		= 6.283185307179586;	// Pi * 2
  PiDiv2	= 1.570796326794897;	// Pi/2
  PiDiv4	= 0.785398185253143;	// Pi/4

function resist(l, s, ro: double): double;
function resistOfTemp(R, T, cte: double): double;
function SonD(D, N: double): double;
function SonD1(D: double): double;
function DonS(S: double): double;
function WireCross(p, l, du, u, ro: double): double;
function dui(i, l, s, ro: double): double;
function dup(p, u, l, s, ro: double): double;
function VoltDividerUout(R1, R2, Uin: double): double;
function resistQ(Uin, Uout, I: double): double;
function XL(L, f: double): double;
function XC(C, f: double): double;
function FRLC(L, C: double): double;
function FRRC(R, C: double): double;
function WaveResist(L, C: double): double;
function du2db(du: double): double;
function dp2db(dp: double): double;
function db2du(db: double): double;
function db2dp(db: double): double;


implementation

Uses Math;

{-------------------------------------------------------
 Расчёт сопротивления проводника в зависимости 
 от его длины и удельного сопротивления.

 Входные параметры;
    l - длина, м;
    s - сечение, мм^2;
    ro - удельное сопротивление, (ом*мм^2)/м.

 Возвращаемое значение:
    сопротивление проводника, Ом.
-------------------------------------------------------}
function resist(l, s, ro: double): double;
Begin
  resist := (l * ro) / s;
end;

{-------------------------------------------------------
 Расчёт сопротивления проводника при определённой
 температуре.

 Входные параметры:
    R - сопротивление проводника при 20 гр. С
    T - расчётная температура, гр. С
    cte - ТКС, %/гр. С

 Возвращаемое значение:
    Сопротивление проводника, Ом.
-------------------------------------------------------}
function resistOfTemp(R, T, cte: double): double;
Begin
  resistOfTemp := R * (1 + cte * (T-20) / 100);
end;

{-------------------------------------------------------
 Расчёт сечения многожильного провода по диаметру 
 одной жилы и количеству жил.

 Входные параметры:
    D - диаметр жилы, мм;
    N - количество жил.
 Возвращаемое значение:
    сечение провода, мм^2
-------------------------------------------------------}
function SonD(D, N: double): double;
Begin
  SonD := PiDiv4 * D * D * N;
end;

{-------------------------------------------------------
 Расчёт сечения одножильного провода по его диаметру.

 Входные параметры:
    D - диаметр провода, мм.
 Возвращаемое значение:
    сечение провода, мм^2
-------------------------------------------------------}
function SonD1(D: double): double;
Begin
  SonD1 := SonD(D, 1);
end;

{-------------------------------------------------------
 Расчёт диаметра одножильного провода по его сечению.

 Входные параметры:
    S - сечение провода, мм^2.
 Возвращаемое значение:
    диаметр провода, мм
-------------------------------------------------------}
function DonS(S: double): double;
Begin
  DonS := SQRT((4 * S)/Pi);
end;

{-------------------------------------------------------
 Расчёт сечения провода в зависимости
 от мощности нагрузки, напряжения питания, 
 допустимого падения напряжения, длины провода и его 
 материала.

 Входные параметры:
    p - мощность нагрузки, Вт;
    l - длина провода, м;
    du - допустимое падение напряжения на проводе, В;
    u - напряжение питания, В;
    ro - удельная проводимость провода, ом*мм^2/м:

 Выходное значение:
    сечение провода в кв. мм.
---------------------------------------------------------}
function WireCross(p, l, du, u, ro: double): double;
Var
  y: double;

Begin
  y := 1.0/ro;

  WireCross := (2 * p * l)/(y * du * u);
end;

{---------------------------------------------------------
 Расчёт падения напряжения на проводе в зависимости от
 сечения, проходящего тока, длины и типа провода.
 Входные параметры:

 Входные параметры:
    i - ток нагрузки, А;
    l - длина провода, м;
    s - сечение провода, кв. мм.;
    ro - удельная проводимость провода, ом*мм^2/м:

 Выходное значение:
    падение напряжения, В. 
---------------------------------------------------------}
function dui(i, l, s, ro: double): double;
Begin
  dui := i * resist(l, s, ro);
end;

{---------------------------------------------------------
 Расчёт падения напряжения на проводе в зависимости от
 сечения, мощности нагрузки, напряжения питания, длины и 
 типа провода.
 Входные параметры:

 Входные параметры:
    p - мощность нагрузки, Вт;
    u - напряжение питания, В;
    l - длина провода, м;
    s - сечение провода, мм^2;
    ro - удельная проводимость провода, ом*мм^2/м:

 Выходное значение:
    падение напряжения, В. 
---------------------------------------------------------}
function dup(p, u, l, s, ro: double): double;
Var
  i: double;
Begin
  i := p / u;
  dup := dui(i, l, s, ro);
end;

{--------------------------------------------------------
 Расчёт выходного напряжения делителя напряжения.

 Входные параметры:
    R1 - сопротивление верхнего элемента, Ом
    R2 - сопротивление нижнего элемента, Ом
    Uin- входное напряжение, В
 
 Возвращаемое значение:
    Напряжение на выходе делителя, В
---------------------------------------------------------}
function VoltDividerUout(R1, R2, Uin: double): double;
Begin
  VoltDividerUout := Uin * (R2/(R1+R2));
end;

{---------------------------------------------------------
 Расчёт гасящего резистора для снятия лишнего
 напряжения с нагрузки.

 Входные параметры:
    Uin - входное напряжение, В
    Uout- напряжение на нагрузке, В
    I - ток нагрузки, А

 Возвращаемое значение:
    сопротивление гасящего резистора, Ом
---------------------------------------------------------}
function resistQ(Uin, Uout, I: double): double;
Begin
  resistQ := (Uout - Uin) / I;
end;

{---------------------------------------------------------
 Расчёт реактивного сопротивления катушки индуктивности
 в зависимости от частоты переменного тока.

 Входные параметры:
    L - индуктивность катушки, Гн;
    f - частота переменного тока, Гц.
 Возвращаемое значение:
    реактивное сопротивление, Ом.
---------------------------------------------------------}
function XL(L, f: double): double;
Begin
  XL := TwoPi * f * L;
end;

{---------------------------------------------------------
 Расчёт реактивного сопротивления конденсатора
 в зависимости от частоты переменного тока.

 Входные параметры:
    C - ёмкость конденсатора, Ф;
    f - частота переменного тока, Гц.
 Возвращаемое значение:
    реактивное сопротивление, Ом.
---------------------------------------------------------}
function XC(C, f: double): double;
Begin
  XC := 1.0/(TwoPi * f * C);
end;

{-------------------------------------------------------
 Расчёт резонансной частоты LC-контура
 в зависимости от индуктивности и ёмкости.

 Входные параметры:
    L - индуктивность катушки, Гн;
    C - ёмкость конденсатора, Ф.
 Возвращаемое значение:
    резонансная частота, Гц.
-------------------------------------------------------}
function FRLC(L, C: double): double;
Begin
  FRLC := 1/(TwoPi * sqrt(L * C));
end;

{-----------------------------------------------------
 Расчёт частоты среза RC-фильтра 1-го порядка
 (наклон 6 дБ на октаву) по уровню -3 дБ.

 Входные параметры:
    R - сопротивления резистора, ом;
    C - ёмкость конденсатора, Ф.
 Возвращаемое значение:
    Частота среза, Гц.
-----------------------------------------------------}
function FRRC(R, C: double): double;

Begin
  FRRC := 1/(TwoPi * R * C);
end;

{-----------------------------------------------------
 Расчёт волнового (характеристического) сопротивления 
 LC-фильтра 1-го порядка. Сопротивление нагрузки фильтра
 должно быть равно этому сопротивлению.

 Входные параметры:
    L — индуктивность катушки, Гн;
    C — ёмкость конденсатора, Ф.
 Возвращаемое значение:
    Характеристическое сопротивление, ом.
------------------------------------------------------}
function WaveResist(L, C: double): double;
Begin
  WaveResist := sqrt(L/C);
// WaveResist := exp(0.5*ln(L/C));
end;

{------------------------------------------------------
 Пересчёт отношения по напряжению в децибелы.

 Входные параметры:
    du - отношение выходного напряжения к входному, разы
 Возвращаемое значение:
    отношение напряжений в децибелах.
------------------------------------------------------}
function du2db(du: double): double;
Begin
  du2db := 20 * LOG10(du);
end;

{------------------------------------------------------
 Пересчёт отношения по мощности в децибелы.

 Входные параметры:
    dp - отношение выходной мощности к входной, разы
 Возвращаемое значение:
    отношение мощностей в децибелах.
------------------------------------------------------}
function dp2db(dp: double): double;
Begin
  dp2db := 10 * LOG10(dp);
end;

{------------------------------------------------------
 Пересчёт отношения по напряжению из децибелов в разы.

 Входные параметры:
    db - отношение выходного напряжения к входному, децибелы
 Возвращаемое значение:
    отношение напряжений, разы.
------------------------------------------------------}
function db2du(db: double): double;
Begin
  db2du := Power(10, (db/20));
end;

{------------------------------------------------------
 Пересчёт отношения по мощности из децибелов в разы.

 Входные параметры:
    db - отношение выходной мощности к входной, децибелы
 Возвращаемое значение:
    отношение мощностей, разы.
------------------------------------------------------}
function db2dp(db: double): double;
Begin
  db2dp := Power(10, (db/10));
end;

end.
