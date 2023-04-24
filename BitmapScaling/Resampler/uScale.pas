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
  and including fast threaded routines.
  Copyright 2003-2023 Renate Schaaf
  Inspired by A.Melander, M.Lischke, E.Grange.
  Supported Delphi-versions: 10.x and up, probably works with
  some earlier versions, but untested.
  The "beef" of the algorithm used is in the routines
  MakeContributors and ProcessRow
  *************************************************************** *)

interface

uses WinApi.Windows, VCL.Graphics, System.Types, System.UITypes,
  System.Threading, System.SysUtils, System.Classes, System.Math,
  System.SyncObjs;

{$IFOPT O-}
{$DEFINE O_MINUS}
{$O+}
{$ENDIF}
{$IFOPT Q+}
{$DEFINE Q_PLUS}
{$Q-}
{$ENDIF}

type
  // Filter types
  TFilter = (cfBox, cfBilinear, cfBicubic, cfMine, cfLanczos, cfBSpline);

const
  // Default radii for the filters, can be made a tad smaller for performance
  DefaultRadius: array [TFilter] of single = (0.5, 1, 2, 2, 3, 2);

type
  // happens right now, if you use a custom thread pool which has not been initialized
  eParallelException = class(Exception);

  TFloatRect = record
    Left, Top, Right, Bottom: double;
  end;

  // amIndependent: all channels are resampled independently, pixels with alpha=0 can contribute
  // to the RGB-part of the result.
  //
  // amPreMultiply: RBG-channels are pre-multiplied by alpha-channel before resampling,
  // after that the resampled alpha-channel is divided out again, unless=0. This means that pixels
  // with alpha=0 have no contribution to the RGB-part of the result.
  //
  // amIgnore: Resampling ignores the alpha-channel and only stores RGB into target. Useful if the alpha-channel
  // is not needed or the target already contains a custom alpha-channel which should not be changed
  //
  // amTransparentColor: The source is resampled while preserving transparent parts as indicatated by TransparentColor.
  // The target can use the same color for transparency. Uses the alpha-channel only internally.
  TAlphaCombineMode = (amIndependent, amPreMultiply, amIgnore,
    amTransparentColor);

  // A TResamplingThread is a simple worker-thread which can run anonymous procedures.
  // Use is not restricted to resampling.
  TResamplingThread = class(TThread)
  private
    fResamplingThreadProc: TProc;
  protected
    procedure Execute; override;
  public
    Wakeup, Done, Ready: TEvent;
    procedure RunAnonProc(aProc: TProc);
    Constructor Create;
    Destructor Destroy; override;
  end;

  // A record defining a simple thread pool. A pointer to such a record can be
  // passed to the ZoomResampleParallelThreads procedure to indicate that this thread
  // pool should be used. This way the procedure can be used in concurrent threads.
  TResamplingThreadPool = record
    private
    ResamplingThreads: array of TResamplingThread;
    Initialized: boolean;
    public
    /// <summary> Creates the threads. Call before you use it in parallel procedures. If already initialized, it will finalize first, don't call it unnecessarily. </summary>
    procedure Initialize(aMaxThreadCount: integer; aPriority: TThreadpriority);
    /// <summary> Frees the threads. Call when your code exits the part where you use parallel resampling to free up memory and CPU-time. If you don't finalize a custom threadpool, you will have a memory leak. </summary>
    procedure Finalize;
  end;

  PResamplingThreadPool = ^TResamplingThreadPool;

/// <summary> Initializes the default resampling thread pool. If already initialized, it does nothing. If not called, the default thread pool is initialized at the first use of a parallel procedure, causing a delay. </summary>
procedure InitDefaultResamplingThreads;

/// <summary> Frees the default resampling threads. If they are initialized and not finalized the Finalization of uScale will do it. </summary>
procedure FinalizeDefaultResamplingThreads;

/// <summary> Resampling of complete bitmaps with various options. Uses the ZoomResample.. functions internally </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Target.Alphaformat will be = Source.Alphaformat. </param>
/// <param name="Filter"> Defines the kernel function for resampling </param>
/// <param name="Radius"> Defines the range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="Parallel"> If true the resampling work is divided into parallel threads. </param>
/// <param name="AlphaCombineMode"> Options for combining the alpha-channel: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
/// <param name="ThreadPool"> Pointer to the TResamplingThreadpool to be used, nil uses a default thread pool. </param>
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
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);

// The following routine is now threadsafe, if each concurrent thread uses a different thread pool

/// <summary> Resamples a rectangle of the Source to the Target using parallel threads. </summary>
/// <param name="NewWidth"> Width of target bitmap. Target will be resized. </param>
/// <param name="NewHeight"> Height of target bitmap. Target will be resized. </param>
/// <param name="Source"> Source bitmap, will be set to pf32bit. Works best if Source.Alphaformat=afIgnored. </param>
/// <param name="Target"> Target bitmap, will be set to pf32bit. Target.Alphaformat will be = Source.Alphaformat. </param>
/// <param name="SourceRect"> Rectangle in the source which will be resampled, has floating point boundaries for smooth zooms. </param>
/// <param name="Filter"> Defines the kernel function for resampling </param>
/// <param name="Radius"> Defines the range of pixels to contribute to the result. Value 0 takes the default radius for the filter. </param>
/// <param name="AlphaCombineMode"> Options for the alpha-channel: amIndependent, amPreMultiply, amIgnore, amTransparentColor </param>
/// <param name="ThreadPool"> Pointer to the TResamplingThreadpool to be used, nil uses a default thread pool</param>
procedure ZoomResampleParallelThreads(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode;
  ThreadPool: PResamplingThreadPool = nil);

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
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);

function FloatRect(Aleft, ATop, ARight, ABottom: double): TFloatRect;
  overload; inline;
function FloatRect(ARect: TRect): TFloatRect; overload; inline;

implementation

var
  _DefaultThreadPool: TResamplingThreadPool;

type
  TFilterFunction = function(x: double): double;

  TBGRAInt = record
    b, g, r, a: integer;
  end;

  PBGRAInt = ^TBGRAInt;

  TBGRAIntArray = array of TBGRAInt;

  TCacheMatrix = array of TBGRAIntArray;

  TIntArray = array of integer;

  TContributor = record
    Min, High: integer;
    // Min: start source pixel
    // High+1: number of source pixels to contribute to the result
    Weights: array of integer; // floats scaled by $100  or $800
  end;

  TContribArray = array of TContributor;

const
  // constants used to divide the work for threading
  _ChunkHeight: integer = 8;
  _MaxThreadCount: integer = 64;

type
  TPrecision = (prLow, prHigh);

const
  PrecisionFacts: array [TPrecision] of integer = ($100, $800);
  PreMultPrecision = 1 shl 2;

  PointCount = 12; // 6 would be Simpson's rule, but I like emphasis on midpoint
  PointCountMinus2 = PointCount - 2;
  PointCountInv = 1 / PointCount;

function FloatRect(Aleft, ATop, ARight, ABottom: double): TFloatRect;
begin
  with Result do
  begin
    Left := Aleft;
    Top := ATop;
    Right := ARight;
    Bottom := ABottom;
  end;
end;

function FloatRect(ARect: TRect): TFloatRect;
begin
  with Result do
  begin
    Left := ARect.Left;
    Top := ARect.Top;
    Right := ARect.Right;
    Bottom := ARect.Bottom;
  end;
end;

// Follow the filter functions.
// They actually never get inlined, because
// MakeContributors uses a procedural variable,
// but their use is not in a time-critical spot.
function Box(x: double): double; inline;
begin
  x := abs(x);
  if x > 1 then
    Result := 0
  else
    Result := 0.5;
end;

function Linear(x: double): double; inline;
begin
  x := abs(x);
  if x < 1 then
    Result := 1 - x
  else
    Result := 0;
end;

function BSpline(x: double): double; inline;
begin
  x := abs(x);
  if x < 0.5 then
    Result := 8 * x * x * (x - 1) + 4 / 3
  else if x < 1 then
    Result := 8 / 3 * sqr(1 - x) * (1 - x)
  else
    Result := 0;
end;

const
  beta = 0.52;
  beta2 = beta * beta;
  alpha = 105 / (16 - 112 * beta2);
  aa = 1 / 7 * alpha;
  bb = -1 / 5 * alpha * (2 + beta2);
  cc = 1 / 3 * alpha * (1 + 2 * beta2);
  dd = -alpha * beta2;

function Mine(x: double): double; inline;
begin
  x := abs(x);
  if x > 1 then
    Result := 0
  else
    Result := 7 * aa * x * x * x * x * x * x + 5 * bb * x * x * x * x + 3 * cc *
      sqr(x) + dd;
end;

const
  ac = -2;

function Bicubic(x: double): double; inline;
begin
  x := abs(x);
  if x < 1 / 2 then
    Result := 4 * (ac + 8) * x * x * x - 2 * (ac + 12) * x * x + 2
  else if x < 1 then
    Result := 2 * ac * (2 * x * x * x - 5 * x * x + 4 * x - 1)
  else
    Result := 0;
end;

function Lanczos(x: double): double; inline;
var
  y, yinv: double;
begin
  x := abs(x);
  if x = 0 then
    Result := 3
  else if x < 1 then
  begin
    y := Pi * x;
    yinv := 1 / y;
    Result := sin(3 * y) * sin(y) * yinv * yinv;
  end
  else
    Result := 0;
end;

const
  FilterFunctions: array [TFilter] of TFilterFunction = (Box, Linear, Bicubic,
    Mine, Lanczos, BSpline);

procedure MakeContributors(r: single; SourceSize, TargetSize: integer;
  SourceStart, SourceFloatwidth: double; Filter: TFilter; precision: TPrecision;
  var Contribs: TContribArray);
// r: Filterradius
var
  xCenter, scale, rr: double;
  x, j: integer;
  x1, x2, x0, x3, delta, dw: double;
  TrueMin, TrueMax, Mx, prec: integer;
  sum, ds: integer;
  FT: TFilterFunction;
begin
  if SourceFloatwidth = 0 then
    SourceFloatwidth := SourceSize;
  scale := SourceFloatwidth / TargetSize;
  prec := PrecisionFacts[precision];
  SetLength(Contribs, TargetSize);

  FT := FilterFunctions[Filter];

  if scale > 1 then
    // downsampling
    rr := r * scale
  else
    // upsampling
    rr := r;
  delta := 1 / rr;
  if scale = 1 then
  begin
    for x := 0 to TargetSize - 1 do
    begin
      Contribs[x].Min := x;
      Contribs[x].High := 0;
      SetLength(Contribs[x].Weights, 1);
      Contribs[x].Weights[0] := prec;
    end;
    exit;
  end;
  for x := 0 to TargetSize - 1 do
  begin
    xCenter := (x + 0.5) * scale;
    TrueMin := Ceil(xCenter - rr + SourceStart - 1);
    TrueMax := Floor(xCenter + rr + SourceStart);
    Contribs[x].Min := Min(max(TrueMin, 0), SourceSize - 1);
    // make sure not to read in negative pixel locations
    Mx := max(Min(TrueMax, SourceSize - 1), 0);
    // make sure not to read past w1-1 in the source
    Contribs[x].High := Mx - Contribs[x].Min;
    Assert(Contribs[x].High >= 0);
    // High=Number of contributing pixels minus 1
    SetLength(Contribs[x].Weights, Contribs[x].High + 1);
    sum := 0;
    with Contribs[x] do
    begin
      x0 := delta * (Min - SourceStart - xCenter + 0.5);
      for j := 0 to High do
      begin
        x1 := x0 - 0.5 * delta;
        x2 := x0 + 0.5 * delta;
        // intersect interval [x1, x2] with the support of the filter
        x1 := max(x1, -1);
        x2 := System.Math.Min(x2, 1);
        // x3 is the new center
        x3 := 0.5 * (x1 + x2);
        // Evaluate integral_x1^x2 FT(x) dx using a mixture of
        // the midpoint rule and the trapezoidal rule.
        // The midpoint parts seems to preserve details
        // while the trapezoidal part and the intersection
        // with the support of the filter prevents artefacts.
        // PointCount=6 would be Simpson's rule.
        dw := PointCountInv * (x2 - x1) *
          (FT(x1) + FT(x2) + PointCountMinus2 * FT(x3));
        // scale float to integer, integer=prec corresponds to float=1
        Weights[j] := round(prec * dw);
        x0 := x0 + delta;
        sum := sum + Weights[j];
      end;
      for j := TrueMin - Min to -1 do
      begin
        // assume the first pixel to be repeated
        x0 := delta * (Min + j - SourceStart - xCenter + 0.5);
        x1 := x0 - 0.5 * delta;
        x2 := x0 + 0.5 * delta;
        x1 := max(x1, -1);
        x2 := System.Math.Min(x2, 1);
        x3 := 0.5 * (x1 + x2);
        dw := PointCountInv * (x2 - x1) *
          (FT(x1) + FT(x2) + PointCountMinus2 * FT(x3));
        ds := round(prec * dw);
        Weights[0] := Weights[0] + ds;
        sum := sum + ds;
      end;
      for j := High + 1 to TrueMax - Min do
      begin
        // assume the last pixel to be repeated
        x0 := delta * (Min + j - SourceStart - xCenter + 0.5);
        x1 := x0 - 0.5 * delta;
        x2 := x0 + 0.5 * delta;
        x1 := max(x1, -1);
        x2 := System.Math.Min(x2, 1);
        x3 := 0.5 * (x1 + x2);
        dw := PointCountInv * (x2 - x1) *
          (FT(x1) + FT(x2) + PointCountMinus2 * FT(x3));
        ds := round(prec * dw);
        Weights[High] := Weights[High] + ds;
        sum := sum + ds;
      end;
      // make sure weights sum up to prec
      Weights[High div 2] := Weights[High div 2] + prec - sum;
    end;
    { with Contribs[x] }
  end; { for x }
end;

procedure Combine(const ps: PRGBQuad; const Weight: integer;
  const Cache: PBGRAInt; const acm: TAlphaCombineMode); inline;
var
  alpha: integer;
begin
  if acm in [amIndependent, amIgnore] then
  begin
    Cache.b := Weight * ps.rgbBlue;
    Cache.g := Weight * ps.rgbGreen;
    Cache.r := Weight * ps.rgbRed;
    if acm = amIndependent then
      Cache.a := Weight * ps.rgbReserved;
  end
  else
  begin
    if ps.rgbReserved > 0 then
    begin
      alpha := Weight * ps.rgbReserved;
      Cache.b := MulDiv(ps.rgbBlue, alpha, PreMultPrecision);
      Cache.g := MulDiv(ps.rgbGreen, alpha, PreMultPrecision);
      Cache.r := MulDiv(ps.rgbRed, alpha, PreMultPrecision);
      Cache.a := alpha;
    end
    else
      Cache^ := Default (TBGRAInt);
  end;
end;

procedure Increase(const ps: PRGBQuad; const Weight: integer;
  const Cache: PBGRAInt; const acm: TAlphaCombineMode); inline;
var
  alpha: integer;
begin
  if acm in [amIndependent, amIgnore] then
  begin
    inc(Cache.b, Weight * ps.rgbBlue);
    inc(Cache.g, Weight * ps.rgbGreen);
    inc(Cache.r, Weight * ps.rgbRed);
    if acm = amIndependent then
      inc(Cache.a, Weight * ps.rgbReserved);
  end
  else if ps.rgbReserved > 0 then
  begin
    alpha := Weight * ps.rgbReserved;
    inc(Cache.b, MulDiv(ps.rgbBlue, alpha, PreMultPrecision));
    inc(Cache.g, MulDiv(ps.rgbGreen, alpha, PreMultPrecision));
    inc(Cache.r, MulDiv(ps.rgbRed, alpha, PreMultPrecision));
    inc(Cache.a, alpha);
  end;
end;

procedure InitTotal(const Cache: PBGRAInt; const Weight: integer;
  var Total: TBGRAInt; const acm: TAlphaCombineMode); inline;
begin
  if acm in [amIndependent, amIgnore] then
  begin
    Total.b := Weight * Cache.b;
    Total.g := Weight * Cache.g;
    Total.r := Weight * Cache.r;
    if acm = amIndependent then
      Total.a := Weight * Cache.a;
  end
  else if Cache.a <> 0 then
  begin
    Total.b := Weight * Cache.b;
    Total.g := Weight * Cache.g;
    Total.r := Weight * Cache.r;
    Total.a := Weight * Cache.a;
  end
  else
    Total := Default (TBGRAInt);
end;

procedure IncreaseTotal(const Cache: PBGRAInt; const Weight: integer;
  var Total: TBGRAInt; const acm: TAlphaCombineMode); inline;
begin
  if acm in [amIndependent, amIgnore] then
  begin
    inc(Total.b, Weight * Cache.b);
    inc(Total.g, Weight * Cache.g);
    inc(Total.r, Weight * Cache.r);
    if acm = amIndependent then
      inc(Total.a, Weight * Cache.a);
  end
  else if Cache.a <> 0 then
  begin
    inc(Total.b, Weight * Cache.b);
    inc(Total.g, Weight * Cache.g);
    inc(Total.r, Weight * Cache.r);
    inc(Total.a, Weight * Cache.a);
  end;
end;

procedure ClampIndependent(const Total: TBGRAInt; const pT: PRGBQuad); inline;
begin
  pT.rgbBlue := Min((max(Total.b, 0) + $1FFFFF) shr 22, 255);
  pT.rgbGreen := Min((max(Total.g, 0) + $1FFFFF) shr 22, 255);
  pT.rgbRed := Min((max(Total.r, 0) + $1FFFFF) shr 22, 255);
  pT.rgbReserved := Min((max(Total.a, 0) + $1FFFFF) shr 22, 255);
end;

procedure ClampIgnore(const Total: TBGRAInt; const pT: PRGBQuad); inline;
begin
  pT.rgbBlue := Min((max(Total.b, 0) + $1FFFFF) shr 22, 255);
  pT.rgbGreen := Min((max(Total.g, 0) + $1FFFFF) shr 22, 255);
  pT.rgbRed := Min((max(Total.r, 0) + $1FFFFF) shr 22, 255);
end;

procedure ClampPreMult(const Total: TBGRAInt; const pT: PRGBQuad); inline;
var
  alpha: byte;
begin
  alpha := Min((max(Total.a, 0) + $7FFF) shr 16, 255);
  if alpha > 0 then
  begin
    pT.rgbBlue := Min((max(Total.b div alpha, 0) + $1FFF) shr 14, 255);
    pT.rgbGreen := Min((max(Total.g div alpha, 0) + $1FFF) shr 14, 255);
    pT.rgbRed := Min((max(Total.r div alpha, 0) + $1FFF) shr 14, 255);
    pT.rgbReserved := alpha;
  end
  else
    pT^ := Default (TRGBQuad);
end;

procedure ProcessRow(y, Sbps, Tbps, xminSource, xmaxSource, xmin,
  xmax: integer; rStart, rTStart: PByte; runstart: PBGRAInt;
  const ContribsX, ContribsY: TContribArray;
  AlphaCombineMode: TAlphaCombineMode); inline;
var
  ps, pT: PRGBQuad;
  rs, rT: PByte;
  x, i, j: integer;
  highx, highy, minx, miny: integer;
  Weightx, Weighty: PInteger;
  Weight: integer;
  Total: TBGRAInt;
  run: PBGRAInt;
begin
  miny := ContribsY[y].Min;
  highy := ContribsY[y].High;
  rs := rStart;
  rT := rTStart;
  Dec(rs, Sbps * miny);
  Dec(rT, Tbps * y);
  inc(rs, 4 * xminSource);
  Weighty := @ContribsY[y].Weights[0];
  ps := PRGBQuad(rs);
  run := runstart;
  Weight := Weighty^;
  for x := xminSource to xmaxSource do
  begin

    Combine(ps, Weight, run, AlphaCombineMode);

    inc(ps);
    inc(run);
  end; // for x
  inc(Weighty);
  Dec(rs, Sbps);
  for j := 1 to highy do
  begin
    ps := PRGBQuad(rs);
    run := runstart;
    Weight := Weighty^;
    for x := xminSource to xmaxSource do
    begin

      Increase(ps, Weight, run, AlphaCombineMode);

      inc(ps);
      inc(run);
    end; // for x
    inc(Weighty);
    Dec(rs, Sbps);
  end; // for j
  pT := PRGBQuad(rT);
  inc(pT, xmin);
  run := runstart;
  var
    jump: integer := xminSource;
  for x := xmin to xmax do
  begin
    minx := ContribsX[x].Min;
    highx := ContribsX[x].High;
    Weightx := @ContribsX[x].Weights[0];
    inc(run, minx - jump);

    InitTotal(run, Weightx^, Total, AlphaCombineMode);

    inc(Weightx);
    inc(run);
    for i := 1 to highx do
    begin

      IncreaseTotal(run, Weightx^, Total, AlphaCombineMode);

      inc(Weightx);
      inc(run);
    end;
    jump := highx + 1 + minx;

    Case AlphaCombineMode of
      amIndependent:
        ClampIndependent(Total, pT);
      amPreMultiply:
        ClampPreMult(Total, pT);
      amIgnore:
        ClampIgnore(Total, pT);
      amTransparentColor:
        ClampPreMult(Total, pT);
    end;

    if AlphaCombineMode = amTransparentColor then
      if pT.rgbReserved > 192 then
        pT.rgbReserved := 255
      else
        pT.rgbReserved := 0;

    inc(pT);
  end; // for x
end;

const
  Precisions: array [TAlphaCombineMode] of TPrecision = (prHigh, prLow,
    prHigh, prLow);

type

  TResamplingThreadSetup = record
    Tbps, Sbps: integer;
    ContribsX, ContribsY: TContribArray;
    rStart, rTStart: PByte;
    ThreadCount: integer;
    xmin, xmax, xminSource, xmaxSource: integer;
    ymin, ymax: TIntArray;
    CacheMatrix: TCacheMatrix;
    procedure PrepareResamplingThreads(NewWidth, NewHeight: integer;
      const Source, Target: TBitmap; Radius: single; Filter: TFilter;
      SourceRect: TFloatRect; AlphaCombineMode: TAlphaCombineMode;
      aMaxThreadCount: integer);
  end;

  PResamplingThreadSetup = ^TResamplingThreadSetup;

procedure TResamplingThreadSetup.PrepareResamplingThreads(NewWidth,
  NewHeight: integer; const Source, Target: TBitmap; Radius: single;
  Filter: TFilter; SourceRect: TFloatRect; AlphaCombineMode: TAlphaCombineMode;
  aMaxThreadCount: integer);
var
  OldWidth, OldHeight: integer;
  yChunkCount: integer;
  yChunk: integer;
  j, Index: integer;
begin
  OldWidth := Source.Width;
  OldHeight := Source.Height;

  Tbps := ((NewWidth * 32 + 31) and not 31) div 8;
  Sbps := ((OldWidth * 32 + 31) and not 31) div 8;

  MakeContributors(Radius, OldWidth, NewWidth, SourceRect.Left,
    SourceRect.Right - SourceRect.Left, Filter, Precisions[AlphaCombineMode],
    ContribsX);
  MakeContributors(Radius, OldHeight, NewHeight, SourceRect.Top,
    SourceRect.Bottom - SourceRect.Top, Filter, Precisions[AlphaCombineMode],
    ContribsY);

  rStart := Source.Scanline[0];
  rTStart := Target.Scanline[0];

  yChunkCount := max(Min(NewHeight div _ChunkHeight + 1, aMaxThreadCount), 2);
  ThreadCount := yChunkCount;

  SetLength(ymin, ThreadCount);
  SetLength(ymax, ThreadCount);

  yChunk := NewHeight div yChunkCount;

  xmin := 0;
  xmax := NewWidth - 1;
  xminSource := ContribsX[0].Min;
  xmaxSource := ContribsX[xmax].Min + ContribsX[xmax].High;
  for j := 0 to yChunkCount - 1 do
  begin
    ymin[j] := j * yChunk;
    if j < yChunkCount - 1 then
      ymax[j] := (j + 1) * yChunk - 1
    else
      ymax[j] := NewHeight - 1;
  end;

  SetLength(CacheMatrix, ThreadCount);
  for Index := 0 to ThreadCount - 1 do
    SetLength(CacheMatrix[Index], xmaxSource - xminSource + 1);
end;

function GetResamplingTask(const RTS: TResamplingThreadSetup; Index: integer;
  AlphaCombineMode: TAlphaCombineMode): TProc;
begin
  Result := procedure
    var
      y: integer;
    begin
      for y := RTS.ymin[Index] to RTS.ymax[Index] do
      begin
        ProcessRow(y, RTS.Sbps, RTS.Tbps, RTS.xminSource, RTS.xmaxSource,
          RTS.xmin, RTS.xmax, RTS.rStart, RTS.rTStart,
          @RTS.CacheMatrix[Index][0], RTS.ContribsX, RTS.ContribsY,
          AlphaCombineMode);

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
  TM: PResamplingThreadPool;
  TransColor: TColor;
  DoSetAlphaFormat: boolean;
begin
  if Radius = 0 then
    Radius := DefaultRadius[Filter];
  if ThreadPool = nil then
  // just initialize _DefaultThreadPool without raising an exception
  begin
    TM := @_DefaultThreadPool;
    if not TM.Initialized then
      TM.Initialize(Min(_MaxThreadCount, TThread.ProcessorCount), tpHigher);
  end
  else
  begin
    TM := ThreadPool;
    if not TM.Initialized then
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

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, Source, Target, Radius,
    Filter, SourceRect, AlphaCombineMode, Length(TM.ResamplingThreads));

  for Index := 0 to RTS.ThreadCount - 1 do
    TM.ResamplingThreads[Index].RunAnonProc(GetResamplingTask(RTS, Index,
      AlphaCombineMode));
  for Index := 0 to RTS.ThreadCount - 1 do
    TM.ResamplingThreads[Index].Done.Waitfor(INFINITE);

  if AlphaCombineMode = amTransparentColor then
    TransferTransparency(Target, TransColor)
  else if DoSetAlphaFormat then
  begin
    Source.AlphaFormat := afDefined;
    Target.AlphaFormat := afDefined;
  end;
end;

var
  ResamplingTasks: array of iTask;

procedure ZoomResampleParallelTasks(NewWidth, NewHeight: integer;
  const Source, Target: TBitmap; SourceRect: TFloatRect; Filter: TFilter;
  Radius: single; AlphaCombineMode: TAlphaCombineMode);
var
  RTS: TResamplingThreadSetup;
  Index: integer;
  TransColor: TColor;
  DoSetAlphaFormat: boolean;
  MaxTasks: integer;
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
  if Length(ResamplingTasks) <> MaxTasks then
    SetLength(ResamplingTasks, MaxTasks);

  RTS.PrepareResamplingThreads(NewWidth, NewHeight, Source, Target, Radius,
    Filter, SourceRect, AlphaCombineMode, MaxTasks);

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
  ContribsX, ContribsY: TContribArray;

  OldWidth, OldHeight, SourceMin, SourceMax: integer;

  Sbps, Tbps: integer;
  rStart, rTStart: PByte;
  // Row start in Source, Target
  Cache: TBGRAIntArray; // cache  of integer valued bgra
  y: integer;
  runstart: PBGRAInt;
  TransColor: TColor;
  DoSetAlphaFormat: boolean;
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

  Tbps := ((NewWidth * 32 + 31) and not 31) div 8;
  Sbps := ((OldWidth * 32 + 31) and not 31) div 8;

  MakeContributors(Radius, OldWidth, NewWidth, SourceRect.Left,
    SourceRect.Right - SourceRect.Left, Filter, Precisions[AlphaCombineMode],
    ContribsX);
  MakeContributors(Radius, OldHeight, NewHeight, SourceRect.Top,
    SourceRect.Bottom - SourceRect.Top, Filter, Precisions[AlphaCombineMode],
    ContribsY);

  rStart := Source.Scanline[0];
  rTStart := Target.Scanline[0];

  SourceMin := ContribsX[0].Min;
  SourceMax := ContribsX[NewWidth - 1].Min + ContribsX[NewWidth - 1].High;

  SetLength(Cache, SourceMax - SourceMin + 1);
  runstart := @Cache[0];

  // Compute colors for each target row at y
  for y := 0 to NewHeight - 1 do

    ProcessRow(y, Sbps, Tbps, SourceMin, SourceMax, 0, NewWidth - 1,
      rStart, rTStart, runstart, ContribsX, ContribsY, AlphaCombineMode);
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

{ TResamplingThread }

constructor TResamplingThread.Create;
begin
  inherited Create(false);
  FreeOnTerminate := false;
  Wakeup := TEvent.Create;
  Done := TEvent.Create;
  Ready := TEvent.Create;
end;

destructor TResamplingThread.Destroy;
begin
  Wakeup.Free;
  Done.Free;
  Ready.Free;
  inherited;
end;

procedure TResamplingThread.Execute;
begin
  While not terminated do
  begin
    Ready.SetEvent;
    Wakeup.Waitfor(INFINITE);
    if not terminated then
    begin
      Wakeup.ResetEvent;
      fResamplingThreadProc;
      Done.SetEvent;
    end;
  end;

end;

procedure TResamplingThread.RunAnonProc(aProc: TProc);
begin
  Ready.Waitfor(INFINITE);
  Ready.ResetEvent;
  Done.ResetEvent;
  fResamplingThreadProc := aProc;
  Wakeup.SetEvent;
end;

{ TResamplingThreadPool }

procedure TResamplingThreadPool.Finalize;
begin
  if not Initialized then
    exit;
  for var i: integer := 0 to Length(ResamplingThreads) - 1 do
  begin
    ResamplingThreads[i].Terminate;
    ResamplingThreads[i].Wakeup.SetEvent;
    ResamplingThreads[i].Free;
    ResamplingThreads[i] := nil;
  end;
  SetLength(ResamplingThreads, 0);
  Initialized := false;
end;

procedure TResamplingThreadPool.Initialize(aMaxThreadCount: integer;
  aPriority: TThreadpriority);
begin
  if Initialized then
    Finalize;
  SetLength(ResamplingThreads, max(aMaxThreadCount, 2));

  for var i: integer := 0 to Length(ResamplingThreads) - 1 do
  begin
    ResamplingThreads[i] := TResamplingThread.Create;
    ResamplingThreads[i].priority := aPriority;
    ResamplingThreads[i].Ready.Waitfor(INFINITE);
  end;
  Initialized := true;
end;

procedure InitDefaultResamplingThreads;
begin
  if _DefaultThreadPool.Initialized then
    exit;
  // creating more threads than processors present does not seem to
  // speed up anything.
  _DefaultThreadPool.Initialize(Min(_MaxThreadCount, TThread.ProcessorCount),
    tpHigher);
end;

procedure FinalizeDefaultResamplingThreads;
begin
  if not _DefaultThreadPool.Initialized then
    exit;
  _DefaultThreadPool.Finalize;
end;

initialization

finalization

FinalizeDefaultResamplingThreads;

{$IFDEF O_MINUS}
{$O-}
{$UNDEF O_MINUS}
{$ENDIF}
{$IFDEF Q_PLUS}
{$Q+}
{$UNDEF Q_PLUS}
{$ENDIF}

end.
