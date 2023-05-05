unit uToolsFMX;

interface

uses
  FMX.Graphics, VCL.Graphics, FMX.Types;

procedure BitmapVCLToFMX(const Source: VCL.Graphics.TBitmap;
  const Target: FMX.Graphics.TBitmap);

/// <summary> Magnifies Source to Target by enlarging pixels. For inspection of the pixel-structure. Sets Source and Target to pf24bit. </summary>
procedure Magnify(const Source, Target: FMX.Graphics.TBitmap; fact: integer);

implementation

procedure BitmapVCLToFMX(const Source: VCL.Graphics.TBitmap;
  const Target: FMX.Graphics.TBitmap);
var
  Data: TBitmapData;
  bps, pitch, y, bpLine: integer;
  ByteSource, ByteTarget: PByte;
begin
  Assert(Source.PixelFormat = pf32bit);
  Target.SetSize(Source.Width, Source.Height);
  Assert(Target.PixelFormat = TPixelFormat.BGRA);
  Assert(Target.Map(TMapAccess.Write, Data));
  ByteSource := Source.ScanLine[0];
  ByteTarget := Data.GetScanline(0);
  bps := ((Source.Width * 32 + 31) and not 31) div 8;
  pitch := Data.pitch;
  bpLine := Data.BytesPerLine;
  for y := 1 to Source.Height do
  begin
    Move(ByteSource^, ByteTarget^, bpLine);
    dec(ByteSource, bps);
    inc(ByteTarget, pitch);
  end;
  Target.Unmap(Data);
end;

type
  TBGRA=record
    b,g,r,a: byte;
  end;
  PBGRA=^TBGRA;

procedure Magnify(const Source, Target: FMX.Graphics.TBitmap; fact: integer);
var
  sw, sh: integer;
  x, y, i, j: integer;
  bpsS, bpsT: integer;
  rS, rT: PByte;
  pS, pT: PBGRA;
  DataSource,DataTarget:TBitmapData;
begin
  sw := Source.Width;
  sh := Source.Height;
  target.Width := fact * sw;
  target.Height := fact * sh;
  Assert(Source.map(TMapAccess.Read,DataSource));
  Assert(Target.map(TMapAccess.Write,DataTarget));
  bpsS := DataSource.Pitch;
  bpsT := DataTarget.Pitch;
  rS := DataSource.GetScanLine(0);
  rT := DataTarget.GetScanline(0);
  for y := 0 to sh - 1 do
  begin
    for j := 1 to fact do
    begin
      pS := PBGRA(rS);
      pT := PBGRA(rT);
      for x := 0 to sw - 1 do
      begin
        for i := 1 to fact do
        begin
          pT^ := pS^;
          inc(pT);
        end;
        inc(pS);
      end;
      inc(rT, bpsT);
    end;
    inc(rS, bpsS);
  end;
  Source.Unmap(DataSource);
  Target.Unmap(DataTarget);
end;

end.
