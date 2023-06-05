unit uToolsLegacy;
// contains some helper routines for loading image formats into a TBitmap and
// utilities to modify the alpha-channel.

interface

uses Windows, Graphics, SysUtils,
  ExtCtrls, uScaleLegacy, uScaleCommonLegacy;

/// <summary> Magnifies Source to Target by enlarging pixels. For inspection of the pixel-structure.  </summary>
procedure Magnify(const Source, target: TBitmap; fact: integer);

/// <summary> Sets the alpha of all pixels to 255. bm must be 32bit </summary>
procedure SetOpaque(const bm: TBitmap);

/// <summary> Copies the alpha-channel of a bitmap to a pf8bit bitmap bAlpha </summary>
procedure CopyAlphaChannel(const bm, bAlpha: TBitmap);

/// <summary> Sets the alpha-value of all pixels to 0 </summary>
procedure ClearAlphaChannel(const bm: TBitmap);

procedure MakeAlphaChannel(const bm: TBitmap);

procedure ScaleStretchHalftone(NewWidth, NewHeight: integer;
  const Source, target: TBitmap; AlphaCombineMode: TAlphaCombineMode);

procedure ApplyAlpha(const bm: TBitmap);  

implementation

uses Math, Classes, Forms;


procedure ClearAlphaChannel(const bm: TBitmap);
begin
  bm.PixelFormat := pf24bit;
  bm.PixelFormat := pf32bit;
end;

procedure ScaleStretchHalftone(NewWidth, NewHeight: integer;
  const Source, target: TBitmap; AlphaCombineMode: TAlphaCombineMode);
var
  p: TPoint;
begin
  Source.PixelFormat := pf32bit;
  target.PixelFormat := pf32bit;
  target.SetSize(NewWidth, NewHeight);
  GetBrushOrgEx(target.Canvas.Handle, p);
  SetStretchBltMode(target.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(target.Canvas.Handle, p.x, p.y, @p);
  StretchBlt(target.Canvas.Handle, 0, 0, NewWidth, NewHeight,
    Source.Canvas.Handle, 0, 0, Source.Width, Source.Height, SRCCopy);
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
    BG.Free;
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

procedure ApplyAlpha(const bm: TBitmap);
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
      pix.rgbBlue:=pix.rgbBlue*pix.rgbReserved div 256;
      pix.rgbGreen:=pix.rgbGreen*pix.rgbReserved div 256;
      pix.rgbRed:=pix.rgbRed*pix.rgbReserved div 256;
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
{$IFOPT R+}
{$DEFINE R_Plus}
{$R-}
{$ENDIF}
  for i := 0 to 255 do
    with pal.lpal.palPalEntry[i] do
    begin
      peRed := i;
      peGreen := i;
      peBlue := i;
    end;
{$IFDEF R_Plus}
{$R+}
{$ENDIF}
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

initialization

finalization

end.
