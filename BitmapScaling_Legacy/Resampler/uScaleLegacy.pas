{ *****************************************************************************
  This file is licensed to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License. A copy of this licence is found in the root directory of
  this project in the file LICENCE.txt or alternatively at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
  ***************************************************************************** }
unit uScaleLegacy;
(* ***************************************************************
  High quality resampling of VCL-bitmaps using various filters
  (Box, Bilinear, Bicubic, Lanczos etc.) and including fast threaded routines.
  Copyright 2003-2023 Renate Schaaf
  Inspired by A.Melander, M.Lischke, E.Grange.
  Supported Delphi-versions: Delphi 2006 and up.
  The "beef" of the algorithm used is in the routines
  MakeContributors and ProcessRow in uScaleCommon
  *************************************************************** *)

interface

uses Windows, Graphics, Types,
  SysUtils, Classes, Math,
  SyncObjs, uScaleCommonLegacy;

{$IFOPT O-}
{$DEFINE O_MINUS}
{$O+}
{$ENDIF}
{$IFOPT Q+}
{$DEFINE Q_PLUS}
{$Q-}
{$ENDIF}


  /// <summary> Resampling of complete bitmaps with various options. Uses the ZoomResample.. functions internally </summary>
  /// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
  /// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
  /// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
  /// <param name="Target"> Target bitmap, will be set to pf32bit. Alphaformat will be = Source.Alphaformat. </param>
  /// <param name="Filter"> Resampling kernel: cfBox, cfBilinear, cfBicubic, cfLanczos </param>
  /// <param name="Radius"> Range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
  /// <param name="Parallel"> If true the resampling work is divided into parallel threads. </param>
  /// <param name="AlphaCombineMode"> Options for alpha: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
  /// <param name="ThreadPool"> Pointer to the TResamplingThreadpool to be used, nil uses a default thread pool. </param>
procedure Resample(NewWidth, NewHeight: integer; const Source, Target: TBitmap;
  Filter: TFilter; Radius: single; Parallel: boolean;
  AlphaCombineMode: TAlphaCombineMode; ThreadPool: TResamplingThreadPool = nil);

/// <summary> Resamples a rectangle of the Source to the Target. Does not use threading. </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in Source to be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Resampling kernel: cfBox, cfBilinear, cfBicubic, cfLanczos </param>
/// <param name="Radius"> Range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for alpha: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
procedure ZoomResample(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);

// The following routine is now threadsafe, if each concurrent thread uses a different thread pool

/// <summary> Resamples a rectangle of the Source to the Target using parallel threads. </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in Source to be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Resampling kernel: cfBox, cfBilinear, cfBicubic, cfLanczos </param>
/// <param name="Radius"> Range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for alpha: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
/// <param name="ThreadPool"> Pointer to the TResamplingThreadpool to be used, nil uses a default thread pool</param>
procedure ZoomResampleParallelThreads(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode;
  ThreadPool: TResamplingThreadPool = nil);

function FloatRect(Aleft, ATop, ARight, ABottom: double): TFloatRect;
  overload; inline;
function FloatRect(ARect: TRect): TFloatRect; overload; inline;

implementation

function FloatRect(Aleft, ATop, ARight, ABottom: double): TFloatRect;
  overload; inline;
begin
  Result.Left := Aleft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

function FloatRect(ARect: TRect): TFloatRect; overload; inline;
begin
  Result := FloatRect(ARect.Left,ARect.Top,ARect.Right,ARect.Bottom);
end;

function TransColorToAlpha(const bm: TBitmap): TColor;
var
  row: PByte;
  pix: PRGBQuad;
  pixColor: TRgbTriple;
  TransColor: TColor;
  bps, x, y: integer;
  function SameColor(p1, p2: PRGBTriple): boolean;
  begin
    Result := (p1.rgbtBlue = p2.rgbtBlue) and (p1.rgbtGreen = p2.rgbtGreen) and
      (p1.rgbtRed = p2.rgbtRed);
  end;

begin
  // GetTransparentColor uses bm.Canvas
  bm.Canvas.Lock;
  Result := bm.TransparentColor;
  bm.Canvas.Unlock;
  TransColor := ColorToRGB(Result);
  pixColor.rgbtBlue := GetBValue(TransColor);
  pixColor.rgbtGreen := GetGValue(TransColor);
  pixColor.rgbtRed := GetRValue(TransColor);
  bps := ((bm.Width * 32 + 31) and not 31) div 8;
  row := bm.Scanline[0];
  for y := 1 to bm.Height do
  begin
    pix := PRGBQuad(row);
    for x := 1 to bm.Width do
    begin
      if SameColor(PRGBTriple(pix), @pixColor) then
        pix.rgbReserved := 0
      else
        pix.rgbReserved := 255;
      inc(pix);
    end;
    Dec(row, bps);
  end;

end;

procedure AlphaToTransparentColor(const bm: TBitmap; TransColor: TColor);
var
  row: PByte;
  pix: PRGBQuad;
  pixColor: TRgbTriple;
  bps, x, y: integer;
  c: TColor;
begin
  c := ColorToRGB(TransColor);
  pixColor.rgbtBlue := GetBValue(c);
  pixColor.rgbtGreen := GetGValue(c);
  pixColor.rgbtRed := GetRValue(c);
  bps := ((bm.Width * 32 + 31) and not 31) div 8;
  row := bm.Scanline[0];
  for y := 1 to bm.Height do
  begin
    pix := PRGBQuad(row);
    for x := 1 to bm.Width do
    begin
      if pix.rgbReserved = 0 then
        PRGBTriple(pix)^ := pixColor
      else
        pix.rgbReserved := 0;
      // clear alpha channel, or draw won't draw it right;
      inc(pix);
    end;
    Dec(row, bps);
  end;
end;

procedure InitTransparency(const Source: TBitmap; var TransColor: TColor);
begin
  TransColor := TransColorToAlpha(Source);
end;

procedure TransferTransparency(const Target: TBitmap; TransColor: TColor);
begin
  AlphaToTransparentColor(Target, TransColor);
  Target.Canvas.Lock;
  Target.TransparentMode := tmFixed;
  Target.TransparentColor := TransColor;
  Target.Canvas.Unlock;
end;

procedure ZoomResampleParallelThreads(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode;
  ThreadPool: TResamplingThreadPool = nil);
var
  RTS: TResamplingThreadSetup;
  Index: integer;
  TP: TResamplingThreadPool;
  TransColor: TColor;
  Sbps, Tbps: integer;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];
  if (ThreadPool = nil) or (ThreadPool = _DefaultThreadPool) then
  // just create _DefaultThreadPool without raising an exception
  begin
    if _DefaultThreadPool=nil then
    InitDefaultResamplingThreads;
    TP := _DefaultThreadPool;
  end
  else
  begin
    TP := ThreadPool;
    if not assigned(TP) then
      raise eParallelException.Create('Thread pool not initialized.');
  end;

  Source.PixelFormat := pf32bit;
  Target.PixelFormat := pf32bit;
  TransColor := 0;
  if AlphaCombineMode = amTransparentColor then
    InitTransparency(Source, TransColor);

  Target.SetSize(NewWidth, NewHeight);
  Tbps := -((NewWidth * 32 + 31) and not 31) div 8;
  Sbps := -((Source.Width * 32 + 31) and not 31) div 8;

  PrepareResamplingThreads(RTS,NewWidth, NewHeight, Source.Width, Source.Height,
    Radius, Filter, SourceRect, AlphaCombineMode, TP.ThreadCount, Sbps, Tbps,
    Source.Scanline[0], Target.Scanline[0]);

  for Index := 0 to RTS.ThreadCount - 1 do
  begin
    TP.ResamplingThreads[Index].Index:=Index;
    TP.ResamplingThreads[Index].PRTS:=@RTS;
    TP.ResamplingThreads[Index].AlphaCombineMode:=AlphaCombineMode;
    TP.ResamplingThreads[Index].RunTask;
  end;
  for Index := 0 to RTS.ThreadCount - 1 do
    TP.ResamplingThreads[Index].Done.Waitfor(INFINITE);

  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
end;

procedure ZoomResample(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);
var
  OldWidth, OldHeight: integer;
  Sbps, Tbps: integer;
  rStart, rTStart: PByte;
  // Row start in Source, Target
  y: integer;
  CacheStart: PBGRAInt;
  TransColor: TColor;
  DoSetAlphaFormat: boolean;
  RTS: TResamplingThreadSetup;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];
  Source.PixelFormat := pf32bit;
  Target.PixelFormat := pf32bit;
  TransColor := 0;
  if AlphaCombineMode = amTransparentColor then
    InitTransparency(Source, TransColor);
  Target.SetSize(NewWidth, NewHeight);

  OldWidth := Source.Width;
  OldHeight := Source.Height;

  Tbps := -((NewWidth * 32 + 31) and not 31) div 8;
  Sbps := -((OldWidth * 32 + 31) and not 31) div 8;

  rStart := Source.Scanline[0];
  rTStart := Target.Scanline[0];

  PrepareResamplingThreads(RTS,NewWidth, NewHeight, OldWidth, OldHeight, Radius,
    Filter, SourceRect, AlphaCombineMode, 1, Sbps, Tbps, rStart, rTStart);

  CacheStart:= @RTS.CacheMatrix[0][0];

  // Compute colors for each target row at y
  for y := 0 to NewHeight - 1 do
    ProcessRow(y, CacheStart, RTS, AlphaCombineMode);

  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor);

end;

procedure Resample(NewWidth, NewHeight: integer; const Source, Target: TBitmap;
  Filter: TFilter; Radius: single; Parallel: boolean;
  AlphaCombineMode: TAlphaCombineMode; ThreadPool: TResamplingThreadPool = nil);
var
  r: TFloatRect;
begin
  r := FloatRect(0, 0, Source.Width, Source.Height);

  if Parallel then

    ZoomResampleParallelThreads(NewWidth, NewHeight, Source, Target, r, Filter,
      Radius, AlphaCombineMode, ThreadPool)

  else

    ZoomResample(NewWidth, NewHeight, Source, Target, r, Filter, Radius,
      AlphaCombineMode);

end;

initialization


finalization

{$IFDEF O_MINUS}
{$O-}
{$UNDEF O_MINUS}
{$ENDIF}
{$IFDEF Q_PLUS}
{$Q+}
{$UNDEF Q_PLUS}
{$ENDIF}

end.
