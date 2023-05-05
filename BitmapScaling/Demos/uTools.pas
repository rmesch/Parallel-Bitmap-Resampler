unit uTools;
// contains some helper routines for loading image formats into a TBitmap,
// utilities to modify the alpha-channel and a class to generate nasty test-bitmaps.

interface

uses WinApi.Windows, WinApi.Wincodec, VCL.Graphics, System.SysUtils,
  VCL.ExtCtrls, System.Types, VCL.Imaging.pngimage, uScale;

/// <summary> Assigns a TPngImage to a TBitmap without setting its alphaformat to afDefined </summary>
procedure PngToBmp(const png: TPngImage; const bmp: TBitmap);

/// <summary> Assigns a TWICImage to a TBitmap without setting its alphaformat to afDefined. A TWICImage can be used for fast decoding of image formats .jpg, .bmp, .png, .ico, .tif. </summary>
procedure WICToBmp(const aWic: TWICImage; const bmp: TBitmap);

// Caution: this routine can alter Source by pre-multiplication with alpha.
// This happens for AlphaCombineMode = amPreMultiply
// amIndependent is not supported
procedure ScaleWICImagingBiCubic(NewWidth, NewHeight: integer;
  const Source, target: TBitmap; AlphaCombineMode: TAlphaCombineMode);

/// <summary> Magnifies Source to Target by enlarging pixels. For inspection of the pixel-structure.  </summary>
procedure Magnify(const Source, target: TBitmap; fact: integer);

/// <summary> Sets the alpha of all pixels to 255. bm must be 32bit </summary>
procedure SetOpaque(const bm: TBitmap);

/// <summary> Copies the alpha-channel of a bitmap to a pf8bit bitmap bAlpha </summary>
procedure CopyAlphaChannel(const bm, bAlpha: TBitmap);

/// <summary> Sets the alpha-value of all pixels to 0 </summary>
procedure ClearAlphaChannel(const bm: TBitmap);

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

procedure MakeAlphaChannel(const bm: TBitmap);

procedure ScaleStretchHalftone(NewWidth, NewHeight: integer;
const Source, Target: TBitmap; AlphaCombineMode: TAlphaCombineMode);

implementation

uses System.Math, System.Classes;

var
  // SourceWIC is created in initialization, this makes its use threadsafe, if used in 1 thread only.
  SourceWIC: TWICImage;

procedure ClearAlphaChannel(const bm: TBitmap);
begin
  bm.PixelFormat := pf24bit;
  bm.PixelFormat := pf32bit;
end;

procedure WICToBmp(const aWic: TWICImage; const bmp: TBitmap);
var
  LWicBitmap: IWICBitmapSource;
  Stride: integer;
  Buffer: array of byte;
  BitmapInfo: TBitmapInfo;
  w, h: integer;
begin
  w := aWic.Width;
  h := aWic.Height;
  Stride := w * 4;
  SetLength(Buffer, Stride * h);

  WICConvertBitmapSource(GUID_WICPixelFormat32bppBGRA, aWic.Handle, LWicBitmap);
  LWicBitmap.CopyPixels(nil, Stride, Length(Buffer), @Buffer[0]);

  FillChar(BitmapInfo, sizeof(BitmapInfo), 0);
  BitmapInfo.bmiHeader.biSize := sizeof(BitmapInfo);
  BitmapInfo.bmiHeader.biWidth := w;
  BitmapInfo.bmiHeader.biHeight := -h;
  BitmapInfo.bmiHeader.biPlanes := 1;
  BitmapInfo.bmiHeader.biBitCount := 32;

  bmp.SetSize(0, 0); // erase pixels
  bmp.PixelFormat := pf32bit;

  // if the alphaformat was afDefined before, this is a good spot
  // for VCL.Graphics to do un-multiplication
  bmp.AlphaFormat := afIgnored;

  bmp.SetSize(w, h);
  SetDIBits(0, bmp.Handle, 0, h, @Buffer[0], BitmapInfo, DIB_RGB_COLORS);
end;

procedure ScaleStretchHalftone(NewWidth, NewHeight: integer;
const Source, Target: TBitmap; AlphaCombineMode: TAlphaCombineMode);
var p: TPoint;
begin
  Source.PixelFormat:=pf32bit;
  if AlphaCombineMode = amPreMultiply then
    Source.AlphaFormat := afDefined
  else
    Source.AlphaFormat := afIgnored;
  target.PixelFormat := pf32bit;
  target.SetSize(NewWidth, NewHeight);
  GetBrushOrgEx(Target.Canvas.Handle,p);
  SetStretchBltMode(target.Canvas.handle,HALFTONE);
  SetBrushOrgEx(Target.Canvas.Handle,p.x,p.y,@p);
  StretchBlt(Target.Canvas.Handle,
    0,0,NewWidth,NewHeight,Source.Canvas.Handle,0,0,Source.Width,Source.Height,SRCCopy);
  Target.AlphaFormat:=afIgnored;
end;

procedure ScaleWICImagingBiCubic(NewWidth, NewHeight: integer;
  const Source, target: TBitmap; AlphaCombineMode: TAlphaCombineMode);
var
  Factory: IWICImagingFactory;
  Scaler: IWICBitmapScaler;
begin
  Source.PixelFormat := pf32bit;
  if AlphaCombineMode = amPreMultiply then
    Source.AlphaFormat := afDefined
  else
    Source.AlphaFormat := afIgnored;
  target.PixelFormat := pf32bit;
  target.SetSize(NewWidth, NewHeight);
  Factory := TWICImage.ImagingFactory;
  SourceWIC.Assign(Source);
  Factory.CreateBitmapScaler(Scaler);
  Scaler.Initialize(SourceWIC.Handle, target.Width, target.Height,
    WICBitmapInterpolationModeHighQualityCubic);
  SourceWIC.Handle := IWICBitmap(Scaler);
  target.Assign(SourceWIC);
  target.AlphaFormat := afIgnored;
  Scaler := nil;
  Factory := nil;
end;

procedure PngToBmp(const png: TPngImage; const bmp: TBitmap);
var
  x, y: integer;
  Rowbmp: PByte;
  Rowpng: PByte;
  RowAlpha: PByteArray;
  PixPng: PRGBTriple;
  PixBmp: PRGBQuad;
begin
  bmp.SetSize(0, 0);
  bmp.PixelFormat := pf32bit;
  bmp.AlphaFormat := afIgnored;
  bmp.SetSize(png.Width, png.Height);
  for y := 0 to bmp.Height - 1 do
  begin
    Rowbmp := bmp.ScanLine[y];
    Rowpng := png.ScanLine[y];
    RowAlpha := png.AlphaScanline[y];
    PixPng := PRGBTriple(Rowpng);
    PixBmp := PRGBQuad(Rowbmp);
    for x := 0 to bmp.Width - 1 do
    begin
      PRGBTriple(PixBmp)^:=PixPng^;
      PixBmp.rgbReserved := RowAlpha[x];
      inc(PixBmp);
      inc(PixPng);
    end;
  end;
end;

procedure Magnify(const Source, target: TBitmap; fact: integer);
var
  sw, sh: integer;
  x, y, i, j: integer;
  bpsS, bpsT: integer;
  rS, rT: PByte;
  pS, pT: PRGBQuad;
begin
  Source.PixelFormat := pf32bit;
  target.PixelFormat := pf32bit;
  sw := Source.Width;
  sh := Source.Height;
  target.Width := fact * sw;
  target.Height := fact * sh;
  bpsS := ((sw * 32 + 31) and not 31) div 8;
  bpsT := ((sw * fact * 32 + 31) and not 31) div 8;
  rS := Source.ScanLine[0];
  rT := target.ScanLine[0];
  for y := 0 to sh - 1 do
  begin
    for j := 1 to fact do
    begin
      pS := PRGBQuad(rS);
      pT := PRGBQuad(rT);
      for x := 0 to sw - 1 do
      begin
        for i := 1 to fact do
        begin
          pT^ := pS^;
          inc(pT);
        end;
        inc(pS);
      end;
      dec(rT, bpsT);
    end;
    dec(rS, bpsS);
  end;
end;

Procedure MakeAlphaChannel(const bm: TBitmap);
var
  r: TRect;
  x, y, w, wc, h, xCenter, yCenter, rw, bps, bpsBG: integer;
  BG: TBitmap;
  rowBG, pixBG, row: PByte;
  pix: PRGBQuad;

  function GradLevel: byte;
  var
    scale, z: double;
    zint: integer;
  begin
    scale := 1 / rw;
    z := scale * sqrt(sqr(x - xCenter) + sqr(y - yCenter));
    zint := min(round(255 * z), 255);
    Result := 255 - zint;
  end;

begin
  w := bm.Width;
  h := bm.Height;
  bps := ((w * 32 + 31) and not 31) div 8;
  bpsBG := ((w * 8 + 31) and not 31) div 8;
  BG := TBitmap.Create;
  try
    BG.PixelFormat := pf8Bit;
    BG.SetSize(w, h);
    rowBG := BG.ScanLine[0];
    BG.Canvas.Brush.Color := clBlack;
    BG.Canvas.FillRect(BG.Canvas.ClipRect);
    r := Rect(w div 8, h div 8, 7 * w div 8, 7 * h div 8);
    xCenter := w div 2;
    yCenter := h div 2;
    rw := min(r.Right - r.Left, r.Bottom - r.Top) div 2;
    dec(rowBG, r.Top * bpsBG);
    inc(rowBG, r.Left);
    for y := r.Top to r.Bottom do
    begin
      pixBG := rowBG;
      for x := r.Left to r.Right do
      begin
        pixBG^ := GradLevel;
        inc(pixBG);
      end;
      dec(rowBG, bpsBG);
    end;
    BG.Canvas.Brush.Color := clWhite;
    BG.Canvas.Pen.Color := clWhite;
    wc := min(w, h);
    r := Rect(0, 0, wc div 2, wc div 2);
    inflateRect(r, -5, -5);
    BG.Canvas.Ellipse(r);
    OffsetRect(r, 0, h - wc div 2);
    inflateRect(r, -10, -10);
    BG.Canvas.Ellipse(r);
    OffsetRect(r, w - wc div 2, 0);
    inflateRect(r, -10, -10);
    BG.Canvas.Ellipse(r);
    row := bm.ScanLine[0];
    rowBG := BG.ScanLine[0];
    for y := 0 to h - 1 do
    begin
      pixBG := rowBG;
      pix := PRGBQuad(row);
      for x := 0 to w - 1 do
      begin
        pix.rgbReserved := pixBG^;
        inc(pix);
        inc(pixBG);
      end;
      dec(row, bps);
      dec(rowBG, bpsBG);
    end;
  finally
    BG.free;
  end;
end;

procedure SetOpaque(const bm: TBitmap);
var
  x, y, w, h, bps: integer;
  row: PByte;
  pix: PRGBQuad;

begin
  Assert(bm.PixelFormat = pf32bit, 'Bitmap must be 32bit');
  w := bm.Width;
  h := bm.Height;
  bps := ((w * 32 + 31) and not 31) div 8;

  row := bm.ScanLine[0];
  for y := 0 to h - 1 do
  begin
    pix := PRGBQuad(row);
    for x := 0 to w - 1 do
    begin
      pix.rgbReserved := 255;
      inc(pix);
    end;
    dec(row, bps);
  end;

end;

type
  LogPal = record
    lpal: TLogPalette;
    dummy: Array [0 .. 255] of TPaletteEntry;
  end;

procedure CopyAlphaChannel(const bm, bAlpha: TBitmap);
var
  x, y, w, h, bps, bpsAlpha: integer;
  row, RowAlpha: PByte;
  pix: PRGBQuad;
  pixAlpha: PByte;
  pal: LogPal;
  i: byte;

begin
  Assert(bm.PixelFormat = pf32bit, 'Bitmap must be 32bit');
  w := bm.Width;
  h := bm.Height;
  bAlpha.PixelFormat := pf8Bit;
  // Create a 256 gray-scale palette
  pal.lpal.palVersion := $300;
  pal.lpal.palNumEntries := 256;
  for i := 0 to 255 do
    with pal.lpal.palPalEntry[i] do
    begin
      peRed := i;
      peGreen := i;
      peBlue := i;
    end;
  bAlpha.Palette := CreatePalette(pal.lpal);
  bAlpha.SetSize(w, h);
  bps := ((w * 32 + 31) and not 31) div 8;
  bpsAlpha := ((w * 8 + 31) and not 31) div 8;
  row := bm.ScanLine[0];
  RowAlpha := bAlpha.ScanLine[0];
  for y := 0 to h - 1 do
  begin
    pix := PRGBQuad(row);
    pixAlpha := RowAlpha;
    for x := 0 to w - 1 do
    begin
      pixAlpha^ := pix.rgbReserved;
      inc(pix);
      inc(pixAlpha);
    end;
    dec(row, bps);
    dec(RowAlpha, bpsAlpha);
  end;
  // ??????
  DeleteObject(bAlpha.Palette);
end;

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

initialization

SourceWIC := TWICImage.Create;

finalization

SourceWIC.free;

end.
