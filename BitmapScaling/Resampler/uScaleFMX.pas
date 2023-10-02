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
unit uScaleFMX;
(* ***************************************************************
  High quality resampling of FMX-bitmaps using various filters
  and including fast threaded routines.
  Copyright © 2003-2023 Renate Schaaf
  Inspired by A.Melander, M.Lischke, E.Grange.
  Supported Delphi-versions: 10.4 and up. The threaded routines might
  not work in 10.3 and below, there were some problems with FMX-TBitmap
  in threads. Right now I can only test 11.3.
  The "beef" of the algorithm used is in the routines
  MakeContributors and ProcessRow in uScaleCommon
  *************************************************************** *)

(* **********!!!!!!!!!!!!!!! Currently for Windows 32 Bit and Windows 64 Bit only. !!!!!!!!!!!!!!!!!*********** *)

interface

uses FMX.Graphics, System.Types, System.UITypes,
  System.Threading, System.SysUtils, System.Classes, System.Math,
  System.SyncObjs, uScaleCommon;


/// <summary> Resampling of complete bitmaps with various options. Uses the ZoomResample.. functions internally </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Target.Alphaformat will be = Source.Alphaformat. </param>
/// <param name="Filter"> Defines the kernel function for resampling </param>
/// <param name="Radius"> Defines the range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="Parallel"> If true the resampling work is divided into parallel threads. </param>
/// <param name="AlphaCombineMode"> Options for combining the alpha-channel: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
procedure Resample(NewWidth, NewHeight: integer; const Source, Target: TBitmap;
  Filter: TFilter; Radius: single; Parallel: boolean;
  AlphaCombineMode: TAlphaCombineMode; ThreadPool: PResamplingThreadPool = nil);

/// <summary> Resamples a rectangle of the Source to the Target. Does not use threading. </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Target.Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in the source which will be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Defines the kernel function for resampling </param>
/// <param name="Radius"> Defines the range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for the alpha-channel: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
procedure ZoomResample(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TRectF; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);

// !!!!! The following routine is not yet threadsafe !!!!!

/// <summary> Resamples a rectangle of the Source to the Target using parallel threads. Currently not threadsafe!</summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Target.Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in the source which will be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Defines the kernel function for resampling </param>
/// <param name="Radius"> Defines the range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for the alpha-channel: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
/// <param name="ThreadPool"> Currently only uses the default threadpool.</param>
procedure ZoomResampleParallelThreads(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TRectF; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode; ThreadPool: PResamplingThreadPool = nil);

// The following procedure allows you to compare performance of TResamplingThreads to
// the built-in TTask-threading. Is currently not threadsafe.
// Timings with TTask tend to be erratic. Sometimes it takes a very long time,
// I think this happens whenever the system deems it necessary to re-initialize
// the threading-framework.

/// <summary> Resamples a rectangle of the Source to the Target using parallel tasks (TTask). </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Target.Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in the source which will be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Defines the kernel function for resampling </param>
/// <param name="Radius"> Defines the range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for the alpha-channel: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
procedure ZoomResampleParallelTasks(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TRectF; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);

type
  // Radius: Pixel-radius for Gaussian blur. Sigma = Radius/5
  // Alpha: PixelResult = Alpha*PixelSource + (1-Alpha)*Blur. Alpha>1 sharpens, Alpha=0 is Gaussian blur
  // Thresh: Threshhold. Sharpen/Blur will only be applied if abs(PixelSource-Blur)>Thresh*255.
  TUnsharpParameters = record
    Alpha, Radius, Thresh: single;
    procedure AutoValues(Width, Height: integer);
  end;

 /// <summary> Applies an unsharp-mask to Source and stores result in Target. Attention: Alpha-channel is copied unchanged. </summary>
procedure UnsharpMask(Source, Target: TBitmap; Parameters: TUnsharpParameters);

/// <summary> Applies an unsharp-mask to Source and stores result in Target using parallel threads.  Attention: Alpha-channel is copied unchanged. </summary>
procedure UnsharpMaskParallel(Source, Target: TBitmap;
  Parameters: TUnsharpParameters; ThreadPool: PResamplingThreadPool = nil);

implementation

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

procedure ZoomResampleParallelTasks(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TRectF; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);
var
  RTS: TResamplingThreadSetup;
  Index: integer;
  MaxTasks: integer;
  ResamplingTasks: array of iTask;
  DataSource, DataTarget: TBitmapData;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];

  Target.SetSize(NewWidth, NewHeight);

  MaxTasks := max(Min(64, TThread.ProcessorCount), 2);

  Assert(Source.Map(TMapAccess.Read, DataSource));
  Assert(Target.Map(TMapAccess.Write, DataTarget));

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, Source.Width, Source.Height,
    Radius, Filter, SourceRect, AlphaCombineMode, MaxTasks, DataSource.Pitch,
    DataTarget.Pitch, DataSource.GetScanline(0), DataTarget.GetScanline(0));

  SetLength(ResamplingTasks, RTS.ThreadCount);

  for Index := 0 to RTS.ThreadCount - 1 do
    ResamplingTasks[Index] :=
      TTask.run(GetResamplingTask(RTS, Index, AlphaCombineMode));
  TTask.WaitForAll(ResamplingTasks, INFINITE);

  Source.Unmap(DataSource);
  Target.Unmap(DataTarget);
end;

procedure ZoomResampleParallelThreads(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TRectF; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode; ThreadPool: PResamplingThreadPool = nil);
var
  RTS: TResamplingThreadSetup;
  Index: integer;
  DataSource, DataTarget: TBitmapData;
  TP: PResamplingThreadPool;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];

  Target.SetSize(NewWidth, NewHeight);

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

  Assert(Source.Map(TMapAccess.Read, DataSource));
  Assert(Target.Map(TMapAccess.Write, DataTarget));

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, Source.Width, Source.Height,
    Radius, Filter, SourceRect, AlphaCombineMode, TP.ThreadCount,
    DataSource.Pitch, DataTarget.Pitch, DataSource.GetScanline(0),
    DataTarget.GetScanline(0));

  for Index := 0 to RTS.ThreadCount - 1 do
    TP.ResamplingThreads[Index].RunAnonProc(GetResamplingTask(RTS, Index,
      AlphaCombineMode));
  for Index := 0 to RTS.ThreadCount - 1 do
    TP.ResamplingThreads[Index].Done.Waitfor(INFINITE);

  Source.Unmap(DataSource);
  Target.Unmap(DataTarget);
end;

procedure ZoomResample(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TRectF; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);
var
  OldWidth, OldHeight: integer;
  Sbps, Tbps: integer;
  rStart, rTStart: PByte;
  y: integer;
  DataSource, DataTarget: TBitmapData;
  RTS: TResamplingThreadSetup;
  CacheStart: PBGRAInt;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];
  Target.SetSize(NewWidth, NewHeight);

  OldWidth := Source.Width;
  OldHeight := Source.Height;

  Assert(Source.Map(TMapAccess.Read, DataSource));
  Assert(Target.Map(TMapAccess.Write, DataTarget));

  Tbps := DataTarget.Pitch;
  Sbps := DataSource.Pitch;

  rStart := DataSource.GetScanline(0);
  rTStart := DataTarget.GetScanline(0);

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, OldWidth, OldHeight, Radius,
    Filter, SourceRect, AlphaCombineMode, 1, Sbps, Tbps, rStart, rTStart);

  CacheStart := @RTS.CacheMatrix[0][0];

  // Compute colors for each target row at y
  for y := 0 to NewHeight - 1 do
    ProcessRow(y, CacheStart, RTS, AlphaCombineMode);

  Source.Unmap(DataSource);
  Target.Unmap(DataTarget);
end;

procedure Resample(NewWidth, NewHeight: integer; const Source, Target: TBitmap;
  Filter: TFilter; Radius: single; Parallel: boolean;
  AlphaCombineMode: TAlphaCombineMode; ThreadPool: PResamplingThreadPool = nil);
var
  r: TRectF;
begin
  r := RectF(0, 0, Source.Width, Source.Height);

  if Parallel then

    ZoomResample(NewWidth, NewHeight, Source, Target, r, Filter, Radius,
      AlphaCombineMode)

  else

    ZoomResample(NewWidth, NewHeight, Source, Target, r, Filter, Radius,
      AlphaCombineMode);

end;

procedure UnsharpMask(Source, Target: TBitmap; Parameters: TUnsharpParameters);
var
  ContribsX, ContribsY: TContribArray;

  Width, Height: integer;

  bps, y: integer;
  rStart, rTStart: PByte;
  beta: single;
  sig, alphaInt: integer;
  runstart: PBGRAInt;
  Cache: TBGRAIntArray;
  DataSource, DataTarget: TBitmapData;
begin
  Width := Source.Width;
  Height := Source.Height;
  Target.SetSize(Width,Height);

  Assert(Source.Map(TMapAccess.Read, DataSource));
  Assert(Target.Map(TMapAccess.Write, DataTarget));

  bps := DataSource.Pitch;

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
  alphaInt := round($800 * $800 * Parameters.Alpha);
  MakeGaussContributors(Parameters.Radius, beta, Width, ContribsX);
  MakeGaussContributors(Parameters.Radius, beta, Height, ContribsY);
  rStart := DataSource.GetScanline(0);
  rTStart := DataTarget.GetScanline(0);


  SetLength(Cache, Width);
  runstart := @Cache[0];

  // Compute colors for each target row at y
  for y := 0 to Height - 1 do
  begin
    ProcessRowUnsharp(y, bps, 0, Width - 1, alphaInt, sig, Parameters.Thresh,
      rStart, rTStart, runstart, ContribsX, ContribsY);
  end;

  Source.Unmap(DataSource);
  Target.Unmap(DataTarget);
end;

procedure UnsharpMaskParallel(Source, Target: TBitmap;
  Parameters: TUnsharpParameters; ThreadPool: PResamplingThreadPool = nil);
var
  ContribsX, ContribsY: TContribArray;

  Width, Height: integer;

  bps: integer;
  rStart, rTStart: PByte; // Row start in Source, Target
  beta: single;
  sig, alphaInt: integer;
  Cache: TCacheMatrix;
  TP: PResamplingThreadPool;
  yChunkCount, ThreadCount, yChunk: integer;
  yminArray, ymaxArray: TIntArray;
  ThreadIndex, j: integer;
  DataSource, DataTarget: TBitmapData;

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
            Parameters.Thresh, rStart, rTStart, runstart, ContribsX, ContribsY);
      end
  end;

begin
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

  Width := Source.Width;
  Height := Source.Height;
  Target.Width := Width;
  Target.Height := Height;

  Assert(Source.Map(TMapAccess.Read, DataSource));
  Assert(Target.Map(TMapAccess.Write, DataTarget));

  bps := DataSource.Pitch;

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
  alphaInt := round($800 * $800 * Parameters.Alpha);
  MakeGaussContributors(Parameters.Radius, beta, Width, ContribsX);
  MakeGaussContributors(Parameters.Radius, beta, Height, ContribsY);
  rStart := DataSource.GetScanline(0);
  rTStart := DataTarget.GetScanline(0);

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
    TP.ResamplingThreads[ThreadIndex].RunAnonProc(GetUnsharpProc(ThreadIndex));
  end;
  for ThreadIndex := 0 to ThreadCount - 1 do
  begin
    TP.ResamplingThreads[ThreadIndex].Done.Waitfor(INFINITE);
  end;

  Source.Unmap(DataSource);
  Target.Unmap(DataTarget);
end;

{ TUnsharpParameters }

procedure TUnsharpParameters.AutoValues(Width, Height: integer);
var
  size: integer;
begin
  size := max(Width, Height);
  Radius := 1 + sqrt(0.008 * size);
  Alpha := 2.7;
  Thresh := 5 / 256; // 5 color levels
end;

initialization

_IsFMX:=true;

finalization


end.
