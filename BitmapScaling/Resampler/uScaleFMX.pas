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
  Copyright 2003-2023 Renate Schaaf
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

initialization

_IsFMX:=true;

finalization


end.
