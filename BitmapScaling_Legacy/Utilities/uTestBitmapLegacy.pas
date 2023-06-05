unit uTestBitmapLegacy;
// contains a class to generate nasty test-bitmaps.

interface

uses Windows, Graphics, SysUtils,
  ExtCtrls;


// classes for generation of test bitmaps
type

  TTestKind = (tkCircles, tkDiagonals, tkRays, tkSpirals);

  TTestGenerator = class
  protected
    // fBitmap: TBitmap;
    w, bps: integer;
    winv: double;
    rstart: PByte;
    procedure SetBitmap(const Value: TBitmap); virtual;
    function GetPixel(x, y: integer): PRGBQuad;
    function Pattern(x, y: integer): double; virtual;
    procedure Generate; virtual;
  public
    destructor Destroy; override;
  end;

  TDiagonalsGenerator = class(TTestGenerator)
  protected
    procedure SetBitmap(const Value: TBitmap); override;
    function Pattern(x, y: integer): double; override;
    procedure Generate; override;
  end;

  TNinePointGenerator = class(TTestGenerator)
  protected
    procedure Generate; override;
  end;

  TCirclesGenerator = class(TNinePointGenerator)
  protected
    function Pattern(x, y: integer): double; override;
  end;

  TRaysGenerator = class(TNinePointGenerator)
  protected
    function Pattern(x, y: integer): double; override;
  end;

  TSpiralsGenerator = class(TNinePointGenerator)
  protected
    function Pattern(x, y: integer): double; override;
  end;

  TTestBitmap = class(TBitmap)
  private
  public
    procedure Generate(w: integer; TestKind: TTestKind);
  end;

implementation

uses Math, Classes;


{ TTestGenerator }

destructor TTestGenerator.Destroy;
begin
  inherited;
end;

procedure TTestGenerator.Generate;
begin

end;

function TTestGenerator.Pattern(x, y: integer): double;
begin
  Result := 0;
end;

procedure TTestGenerator.SetBitmap(const Value: TBitmap);

begin
  if Value <> nil then
  begin
    Value.PixelFormat := pf32bit;
    w := Value.Width;
    Value.Height := w;
    bps := ((w * 32 + 31) and not 31) div 8;
    rstart := Value.ScanLine[0];
  end;
  // fBitmap := Value;
end;

function TTestGenerator.GetPixel(x, y: integer): PRGBQuad;
var
  p: PByte;
begin
  p := rstart;
  dec(p, y * bps);
  Result := PRGBQuad(p);
  inc(Result, x);
end;

{ TTestBitmap }

type
  TestGeneratorClass = class of TTestGenerator;

const
  TG: array [TTestKind] of TestGeneratorClass = (TCirclesGenerator,
    TDiagonalsGenerator, TRaysGenerator, TSpiralsGenerator);

procedure TTestBitmap.Generate(w: integer; TestKind: TTestKind);
var
  TestGenerator: TTestGenerator;
begin
  PixelFormat := pf32bit;
  Width := w;
  Height := w;
  TestGenerator := TG[TestKind].Create;
  try
    TestGenerator.SetBitmap(self);
    TestGenerator.Generate;
  finally
    TestGenerator.free;
  end;
end;

{ TDiagonalsGenerator }

procedure TDiagonalsGenerator.Generate;
var
  pix: PRGBQuad;
  x, y: integer;
  b: byte;
  level: double;
begin
  for y := 0 to w - 1 do
  begin
    for x := 0 to w - 1 do
    begin
      pix := GetPixel(x, y);
      level := Pattern(x, y);
      if level > 255 then
        level := 255;
      if level < 0 then
        level := 0;
      b := round(level);
      pix.rgbRed := b;
      pix.rgbGreen := b;
      pix.rgbBlue := b;
      pix.rgbReserved := 255; // make opaque
    end;
  end;

end;

function TDiagonalsGenerator.Pattern(x, y: integer): double;
var
  r2: double;
begin
  r2 := 1 / 2 * sqr(2 * w - x - 0.5 - y - 0.5);
  Result := 255 * max((-sin(Pi * r2 * winv / 6)), 0);
end;

procedure TDiagonalsGenerator.SetBitmap(const Value: TBitmap);
begin
  inherited;
  winv := 1 / (w * sqrt(2));
end;

function FCubic(x: double): double;
begin
  if x < 0 then
    x := -x;
  x := 2 * x;
  if x > 2 then
    Result := 0
  else if x > 1 then
    Result := 8 / 3 - 4 * x + 2 * x * x - 1 / 3 * x * x * x
  else
    Result := x * x * x - 2 * x * x + 4 / 3
end;

function arg(x, y: double): double;
begin
  if x > 0 then
    Result := arctan(y / x)
  else if x = 0 then
    if y > 0 then
      Result := Pi / 2
    else if y < 0 then
      Result := -Pi / 2
    else
      Result := 0
  else
    Result := arctan(y / x) + Pi;

end;

{ TNinePointGenerator }

procedure TNinePointGenerator.Generate;
var
  pix: PRGBQuad;
  row: PByte;
  x, y, i: integer;
  b: byte;
  center: array [0 .. 8] of TPoint;
  weights, levels: array [0 .. 8] of double;
  dist, maxdist, totalweight, level, fact: double;
begin
  center[0] := Point(w div 2, w div 2);
  center[1] := Point(0, 0);
  center[2] := Point(w div 2, 0);
  center[3] := Point(w, 0);
  center[4] := Point(0, w div 2);
  center[5] := Point(w, w div 2);
  center[6] := Point(0, w);
  center[7] := Point(w div 2, w);
  center[8] := Point(w, w);
  maxdist := w / sqrt(2);
  winv := 1 / maxdist;
  row := rstart;
  for y := 0 to w - 1 do
  begin
    pix := PRGBQuad(row);
    for x := 0 to w - 1 do
    begin
      totalweight := 0;
      for i := 0 to 8 do
      begin
        dist := sqrt(sqr(x + 0.5 - center[i].x) + sqr(y + 0.5 - center[i].y));
        weights[i] := FCubic(2 * dist / w);
        totalweight := totalweight + weights[i];
        levels[i] := Pattern(x - center[i].x, y - center[i].y);
      end;
      if totalweight > 0 then
        fact := 1 / totalweight
      else
        fact := 0;
      level := 0;
      for i := 0 to 8 do
        level := level + fact * weights[i] * levels[i];
      if level > 255 then
        level := 255;
      if level < 0 then
        level := 0;
      b := round(level);
      pix.rgbRed := b;
      pix.rgbGreen := b;
      pix.rgbBlue := b;
      pix.rgbReserved := 255;
      inc(pix);
    end;
    dec(row, bps);
  end;

end;

{ TCirclesGenerator }

function TCirclesGenerator.Pattern(x, y: integer): double;
var
  r2: double;
begin
  r2 := sqr(x + 0.5) + sqr(y + 0.5);
  // result := 256 * (-cos(Pi * r2 * winv / 2));
  Result := 128 * (1 - cos(0.75 * Pi * r2 * winv));
  Result := max(Result, 0);
end;

{ TRaysGenerator }

function TRaysGenerator.Pattern(x, y: integer): double;
var
  theta: double;
begin
  theta := arg(x + 0.5, y + 0.5);
  Result := 255 * max((-sin(35 * theta)), 0);
  // result := 128 * max((1- sin(24 * theta)),0);
end;

{ TSpiralsGenerator }

function TSpiralsGenerator.Pattern(x, y: integer): double;
var
  r, theta: double;
begin
  theta := arg(x + 0.5, y + 0.5);
  r := 0.2 * power(sqr(x + 0.5) + sqr(y + 0.5), 0.45);

  Result := 255 * max((-sin(15 * theta + r)), 0);
  // result := 128 * max((1- sin(theta+2*r)),0);
end;

end.
