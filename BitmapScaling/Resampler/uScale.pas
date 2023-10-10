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
unit uScale;
(* ***************************************************************
  High quality resampling of VCL-bitmaps using various filters
  (Box, Bilinear, Bicubic, Lanczos etc.) and including fast threaded routines.
  Copyright © 2003-2023 Renate Schaaf
  Inspired by A.Melander, M.Lischke, E.Grange.
  Supported Delphi-versions: 10.x and up, probably works with
  some earlier versions, but untested. Right now I can only test on 11.3.
  Any feedback on earlier versions welcome.
  The "beef" of the algorithm used is in the routines
  MakeContributors and ProcessRow in uScaleCommon
  *************************************************************** *)

interface

{$IFOPT O-}
{$DEFINE O_MINUS}
{$O+}
{$ENDIF}
{$IFOPT Q+ }
{$DEFINE Q_PLUS }
{$Q- }
{$ENDIF }

uses WinApi.Windows,
  VCL.Graphics,
  System.Types,
  System.UITypes,
  System.Threading,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.SyncObjs,
  uScaleCommon;

type

  TFloatRect = TRectF;

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
  AlphaCombineMode: TAlphaCombineMode; ThreadPool: PResamplingThreadPool = nil);

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
  ThreadPool: PResamplingThreadPool = nil);

// The following procedure allows you to compare performance of TResamplingThreads to
// the built-in TTask-threading. Is now threadsafe.
// Timings with TTask tend to be erratic. Sometimes it takes a very long time,
// I think this happens whenever the system deems it necessary to re-initialize
// the threading-framework.

/// <summary> Resamples a rectangle of the Source to the Target using parallel tasks (TTask). Is threadsafe. </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in Source to be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Resampling kernel: cfBox, cfBilinear, cfBicubic, cfLanczos </param>
/// <param name="Radius"> Range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for alpha: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
procedure ZoomResampleParallelTasks(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);

type
  // Radius: Pixel-radius for Gaussian blur. Sigma = Radius/SigmaInv.
  // Value of SigmaInv: See function Gauss in uScaleCommon.
  // The value of SigmaInv is chosen so the Weight at r is 0.01 times the Weight at 0.

  // Alpha: PixelResult = Alpha*PixelSource + (1-Alpha)*Blur. Alpha>1 sharpens, Alpha=0 is Gaussian blur

  // Thresh: Threshhold. Sharpen/Blur will only be applied if abs(PixelSource-Blur)>Thresh*255.
  TUnsharpParameters = record
    Alpha, Radius, Thresh, Gamma: single;
    /// <summary Computes parameters for given image size WidthxHeight, which mostly give a nice looking sharpening effect. Based on experiment. </summary>
    procedure AutoValues(Width, Height: integer);
  end;

  /// <summary> Applies an unsharp-mask to Source and stores result in Target. Attention: Alpha-channel is copied unchanged. </summary>
procedure UnsharpMask(const Source, Target: TBitmap;
  Parameters: TUnsharpParameters; AlphaCombineMode: TAlphaCombineMode);

/// <summary> Applies an unsharp-mask to Source and stores result in Target using parallel threads.  Attention: Alpha-channel is copied unchanged. </summary>
procedure UnsharpMaskParallel(const Source, Target: TBitmap;
  Parameters: TUnsharpParameters; AlphaCombineMode: TAlphaCombineMode;
  ThreadPool: PResamplingThreadPool = nil);

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
  Result := TRectF(ARect);
end;

function GetResamplingTask(const RTS: TResamplingThreadSetup; Index: integer;
  AlphaCombineMode: TAlphaCombineMode): TProc;
begin
  Result := procedure
    var
      y, ymin, ymax: integer;
      CacheStart: PBGRAInt;
    begin
      CacheStart := @RTS.CacheMatrix[Index][0];
      ymin := RTS.ymin[Index];
      ymax := RTS.ymax[Index];
      for y := ymin to ymax do
      begin
        ProcessRow(y, CacheStart, RTS, AlphaCombineMode);

      end; // for y
    end; // procedure
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
  Target.TransparentMode := TTransParentMode.tmFixed;
  Target.TransparentColor := TransColor;
  Target.Canvas.Unlock;
end;

procedure ZoomResampleParallelThreads(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode;
  ThreadPool: PResamplingThreadPool = nil);
var
  RTS: TResamplingThreadSetup;
  Index: integer;
  TP: PResamplingThreadPool;
  TransColor: TColor;
  DoSetAlphaFormat: boolean;
  Sbps, Tbps: integer;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];
  if (ThreadPool = nil) or (ThreadPool = @_DefaultThreadPool) then
  // just initialize _DefaultThreadPool without raising an exception
  begin
    TP := @_DefaultThreadPool;
    if not TP.Initialized then
      TP.Initialize(Min(_MaxThreadCount, TThread.ProcessorCount), tpHigher);
  end
  else
  begin
    TP := ThreadPool;
    if not TP.Initialized then
      raise eParallelException.Create('Thread pool not initialized.');
  end;

  Source.PixelFormat := pf32bit;
  Target.PixelFormat := pf32bit;
  DoSetAlphaFormat := (Source.AlphaFormat = afDefined);
  Source.AlphaFormat := afIgnored;
  Target.AlphaFormat := afIgnored;
  TransColor := 0;
  if AlphaCombineMode = amTransparentColor then
    InitTransparency(Source, TransColor);

  Target.SetSize(NewWidth, NewHeight);
  Tbps := -4 * NewWidth;
  Sbps := -4 * Source.Width;

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, Source.Width, Source.Height,
    Radius, Filter, SourceRect, AlphaCombineMode, TP.ThreadCount, Sbps, Tbps,
    Source.Scanline[0], Target.Scanline[0]);

  for Index := 0 to RTS.ThreadCount - 1 do
    TP.ResamplingThreads[Index].RunAnonProc(GetResamplingTask(RTS, Index,
      AlphaCombineMode));
  for Index := 0 to RTS.ThreadCount - 1 do
    TP.ResamplingThreads[Index].Done.Waitfor(INFINITE);

  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
  else if DoSetAlphaFormat then
  begin
    Source.AlphaFormat := afDefined;
    Target.AlphaFormat := afDefined;
  end;
end;

procedure ZoomResampleParallelTasks(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);
var
  RTS: TResamplingThreadSetup;
  Index: integer;
  TransColor: TColor;
  DoSetAlphaFormat: boolean;
  MaxTasks: integer;
  ResamplingTasks: array of iTask;
  Sbps, Tbps: integer;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];
  Source.PixelFormat := pf32bit;
  Target.PixelFormat := pf32bit;
  DoSetAlphaFormat := (Source.AlphaFormat = afDefined);
  Source.AlphaFormat := afIgnored;
  Target.AlphaFormat := afIgnored;
  TransColor := 0;
  if AlphaCombineMode = amTransparentColor then
    InitTransparency(Source, TransColor);
  Target.SetSize(NewWidth, NewHeight);

  MaxTasks := max(Min(64, TThread.ProcessorCount), 2);

  Tbps := -((NewWidth * 32 + 31) and not 31) div 8;
  Sbps := -((Source.Width * 32 + 31) and not 31) div 8;

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, Source.Width, Source.Height,
    Radius, Filter, SourceRect, AlphaCombineMode, MaxTasks, Sbps, Tbps,
    Source.Scanline[0], Target.Scanline[0]);
  SetLength(ResamplingTasks, RTS.ThreadCount);

  for Index := 0 to RTS.ThreadCount - 1 do
    ResamplingTasks[Index] :=
      TTask.run(GetResamplingTask(RTS, Index, AlphaCombineMode));
  TTask.WaitForAll(ResamplingTasks, INFINITE);

  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
  else if DoSetAlphaFormat then
  begin
    Source.AlphaFormat := afDefined;
    Target.AlphaFormat := afDefined;
  end;
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
  DoSetAlphaFormat := (Source.AlphaFormat = afDefined);
  Source.AlphaFormat := afIgnored;
  Target.AlphaFormat := afIgnored;
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

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, OldWidth, OldHeight, Radius,
    Filter, SourceRect, AlphaCombineMode, 1, Sbps, Tbps, rStart, rTStart);

  CacheStart := @RTS.CacheMatrix[0][0];

  // Compute colors for each target row at y
  for y := 0 to NewHeight - 1 do
    ProcessRow(y, CacheStart, RTS, AlphaCombineMode);

  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
  else if DoSetAlphaFormat then
  begin
    Source.AlphaFormat := afDefined;
    Target.AlphaFormat := afDefined;
  end;
end;

procedure Resample(NewWidth, NewHeight: integer; const Source, Target: TBitmap;
  Filter: TFilter; Radius: single; Parallel: boolean;
  AlphaCombineMode: TAlphaCombineMode; ThreadPool: PResamplingThreadPool = nil);
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

procedure DecodeGamma(const Source, Target: TBitmap);
var
  ps, pt: PBGRA;
  rs, rt: PByte;
  i, j: integer;
  stride: integer;
begin
  Target.PixelFormat := pf32bit;
  Target.SetSize(Source.Width, Source.Height);
  stride := -4 * Source.Width;
  rs := Source.Scanline[0];
  rt := Target.Scanline[0];
  for j := 1 to Source.Height do
  begin
    ps := PBGRA(rs);
    pt := PBGRA(rt);
    for i := 1 to Source.Width do
    begin
      pt.b := GammaDecodingTable[ps.b];
      pt.g := GammaDecodingTable[ps.g];
      pt.r := GammaDecodingTable[ps.r];
      pt.a := ps.a;
      inc(ps);
      inc(pt);
    end;
    inc(rs, stride);
    inc(rt, stride);
  end;

end;

procedure UnsharpMask(const Source, Target: TBitmap;
  Parameters: TUnsharpParameters; AlphaCombineMode: TAlphaCombineMode);
var
  ContribsX, ContribsY: TContribArray;

  Width, Height: integer;

  bps, y: integer;
  rStart, rTStart: PByte;
  beta: single;
  sig, alphaInt: integer;
  runstart: PBGRAInt;
  Cache: TBGRAIntArray;
  Temp: TBitmap;
  DoGamma, DoSetAlphaFormat: boolean;
  TransColor: TColor;
begin
  if Parameters.Radius = 0 then
  begin
    Target.Assign(Source);
    Exit;
  end
  else if Parameters.Radius < 0 then
    raise Exception.Create('Radius cannot be negative');
  Source.PixelFormat := pf32bit;
  Target.PixelFormat := pf32bit;
  Width := Source.Width;
  Height := Source.Height;

  DoSetAlphaFormat := (Source.AlphaFormat = afDefined);
  Source.AlphaFormat := afIgnored;
  Target.AlphaFormat := afIgnored;
  TransColor := 0;
  if AlphaCombineMode = amTransparentColor then
    InitTransparency(Source, TransColor);

  Target.SetSize(Width, Height);

  bps := -4 * Width;
  DoGamma := Parameters.Gamma <> 1;
  Temp := TBitmap.Create;
  try
    if DoGamma then
    begin
      MakeGammaTables(Parameters.Gamma);
      DecodeGamma(Source, Temp);
    end
    else
      Temp.Assign(Source);

    if Parameters.Alpha > 1 then
    begin
      beta := sqrt(Parameters.Alpha - 1);
      sig := -1;
    end
    else
    begin
      beta := sqrt(1 - Parameters.Alpha);
      sig := 1;
    end;

    alphaInt := round(GaussScale * GaussScale * Parameters.Alpha);
    MakeGaussContributors(Parameters.Radius, beta, Width, ContribsX);
    MakeGaussContributors(Parameters.Radius, beta, Height, ContribsY);
    rStart := Temp.Scanline[0];
    rTStart := Target.Scanline[0];

    SetLength(Cache, Width);
    runstart := @Cache[0];

    // Compute colors for each target row at y
    for y := 0 to Height - 1 do
    begin
      ProcessRowUnsharp(y, bps, 0, Width - 1, alphaInt, sig, Parameters.Thresh,
        rStart, rTStart, runstart, ContribsX, ContribsY, DoGamma,
        AlphaCombineMode);
    end;
  finally
    Temp.Free;
  end;
  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
  else if DoSetAlphaFormat then
  begin
    Source.AlphaFormat := afDefined;
    Target.AlphaFormat := afDefined;
  end;
end;

procedure UnsharpMaskParallel(const Source, Target: TBitmap;
  Parameters: TUnsharpParameters; AlphaCombineMode: TAlphaCombineMode;
  ThreadPool: PResamplingThreadPool = nil);
var
  ContribsX, ContribsY: TContribArray;

  Width, Height: integer;

  bps: integer;
  rStart, rTStart: PByte;
  beta: single;
  sig, alphaInt: integer;
  Cache: TCacheMatrix;
  TP: PResamplingThreadPool;
  yChunkCount, ThreadCount, yChunk: integer;
  yminArray, ymaxArray: TIntArray;
  ThreadIndex, j: integer;
  Temp: TBitmap;
  DoGamma, DoSetAlphaFormat: boolean;
  TransColor: TColor;

  function GetUnsharpProc(Index: integer): TProc;
  begin
    Result := procedure
      var
        ymin, ymax, y: integer;
        runstart: PBGRAInt;
      begin
        ymin := yminArray[Index];
        ymax := ymaxArray[Index];
        runstart := @Cache[Index][0];
        for y := ymin to ymax do
          ProcessRowUnsharp(y, bps, 0, Width - 1, alphaInt, sig,
            Parameters.Thresh, rStart, rTStart, runstart, ContribsX, ContribsY,
            DoGamma, AlphaCombineMode);
      end
  end;

begin
  if Parameters.Radius = 0 then
  begin
    Target.Assign(Source);
    Exit;
  end
  else if Parameters.Radius < 0 then
    raise Exception.Create('Radius cannot be negative');
  if (ThreadPool = nil) or (ThreadPool = @_DefaultThreadPool) then
  // just initialize _DefaultThreadPool without raising an exception
  begin
    TP := @_DefaultThreadPool;
    if not TP.Initialized then
      TP.Initialize(Min(_MaxThreadCount, TThread.ProcessorCount - 1), tpHigher);
  end
  else
  begin
    TP := ThreadPool;
    if not TP.Initialized then
      raise eParallelException.Create('Thread pool not initialized.');
  end;

  Source.PixelFormat := pf32bit;
  Target.PixelFormat := pf32bit;
  Width := Source.Width;
  Height := Source.Height;

  DoSetAlphaFormat := (Source.AlphaFormat = afDefined);
  Source.AlphaFormat := afIgnored;
  Target.AlphaFormat := afIgnored;
  TransColor := 0;
  if AlphaCombineMode = amTransparentColor then
    InitTransparency(Source, TransColor);

  Target.SetSize(Width, Height);
  bps := -4 * Width;

  DoGamma := Parameters.Gamma <> 1;
  Temp := TBitmap.Create;
  try
    if DoGamma then
    begin
      MakeGammaTables(Parameters.Gamma);
      DecodeGamma(Source, Temp);
    end
    else
      Temp.Assign(Source);

    if Parameters.Alpha > 1 then
    begin
      beta := sqrt(Parameters.Alpha - 1);
      sig := -1;
    end
    else
    begin
      beta := sqrt(1 - Parameters.Alpha);
      sig := 1;
    end;
    alphaInt := round(GaussScale * GaussScale * Parameters.Alpha);
    MakeGaussContributors(Parameters.Radius, beta, Width, ContribsX);
    MakeGaussContributors(Parameters.Radius, beta, Height, ContribsY);
    rStart := Temp.Scanline[0];
    rTStart := Target.Scanline[0];

    yChunkCount := max(Min(Height div _ChunkHeight + 1, TP.ThreadCount), 1);
    ThreadCount := yChunkCount;

    SetLength(yminArray, ThreadCount);
    SetLength(ymaxArray, ThreadCount);

    yChunk := Height div yChunkCount;

    for j := 0 to yChunkCount - 1 do
    begin
      yminArray[j] := j * yChunk;
      if j < yChunkCount - 1 then
        ymaxArray[j] := (j + 1) * yChunk - 1
      else
        ymaxArray[j] := Height - 1;
    end;

    SetLength(Cache, ThreadCount);
    for ThreadIndex := 0 to ThreadCount - 1 do
      SetLength(Cache[ThreadIndex], Width);

    for ThreadIndex := 0 to ThreadCount - 1 do
    begin
      TP.ResamplingThreads[ThreadIndex].RunAnonProc
        (GetUnsharpProc(ThreadIndex));
    end;
    for ThreadIndex := 0 to ThreadCount - 1 do
    begin
      TP.ResamplingThreads[ThreadIndex].Done.Waitfor(INFINITE);
    end;
  finally
    Temp.Free;
  end;
  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
  else if DoSetAlphaFormat then
  begin
    Source.AlphaFormat := afDefined;
    Target.AlphaFormat := afDefined;
  end;
end;

{ TUnsharpParameters }

procedure TUnsharpParameters.AutoValues(Width, Height: integer);
var
  size: integer;
begin
  size := max(Width, Height);
  Radius := 0.5 + sqrt(0.007 * size);
  Alpha := 2.5;
  Thresh := 5 / 256; // 5 color levels
  Gamma := 1;
end;

initialization

_IsFMX := false;

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
