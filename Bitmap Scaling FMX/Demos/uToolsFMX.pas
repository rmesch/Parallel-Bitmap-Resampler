unit uToolsFMX;

interface

uses
FMX.Graphics, VCL.Graphics, FMX.Types;

procedure BitmapVCLToFMX(const Source: VCL.Graphics.TBitmap; const Target: FMX.Graphics.TBitmap);

implementation

procedure BitmapVCLToFMX(const Source: VCL.Graphics.TBitmap; const Target: FMX.Graphics.TBitmap);
var Data: TBitmapData;
    bps,pitch,y: integer;
    ByteSource,ByteTarget: PByte;
begin
  Assert(Source.PixelFormat=pf32bit);
  Target.SetSize(Source.Width,Source.Height);
  Assert(Target.PixelFormat=TPixelFormat.BGRA);
  Assert(Target.Map(TMapAccess.Write,Data));
  ByteSource:=Source.ScanLine[0];
  ByteTarget:=Data.GetScanline(0);
  bps:=((Source.Width * 32 + 31) and not 31) div 8;
  pitch:=Data.Pitch;
  for y := 1 to Source.Height do
  begin
    Move(ByteSource^,ByteTarget^,bps);
    dec(ByteSource,bps);
    inc(ByteTarget,pitch);
  end;
  Target.Unmap(Data);
end;

end.
