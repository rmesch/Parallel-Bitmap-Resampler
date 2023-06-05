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

  { ***************************************************************************
    This unit contains types constants and procedures used by uScaleLegacy. If you use uScaleLegacy,
    also add uScaleCommonLegacy to the uses clause.
    ****************************************************************************}

unit uScaleCommonLegacy;

interface

uses Windows, Types, SysUtils, Math,
  SyncObjs, Classes;

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
  DefaultRadius: array[TFilter] of single = (0.5, 1, 2, 2, 3, 2);

type
  // happens right now, if you use a custom thread pool which has not been initialized
  eParallelException = class(Exception);

  // amIndependent: all channels are resampled independently, pixels with alpha=0 can contribute
  // to the RGB-part of the result.
  //
  // amPreMultiply: RBG-channels are pre-multiplied by alpha-channel before resampling,
  // after that the resampled alpha-channel is divided out again, unless=0. This means that pixels
  // with alpha=0 have no contribution to the RGB-part of the result.
  //
  // amIgnore: Resampling ignores the alpha-channel and only stores RGB into target.
  // VCL-version: Target-alpha is unchanged. Useful if the alpha-channel
  // is not needed or the target already contains a custom alpha-channel which should not be changed
  // FMX-version: Target-alpha is set to 255. Otherwise the FMX-controls would not display the target.
  //
  // amTransparentColor: The source is resampled while preserving transparent parts as indicatated by TransparentColor.
  // The target can use the same color for transparency. Uses the alpha-channel only internally.
  // Currently not supported for FMX.
  TAlphaCombineMode = (amIndependent, amPreMultiply, amIgnore,
    amTransparentColor);

  TFloatRect = record
    Left, Top, Right, Bottom: double;
  end;

  TBGRA = record
    b, g, r, a: byte;
  end;

  PBGRA = ^TBGRA;

  TBGRAInt = record
    b, g, r, a: integer;
  end;

  PBGRAInt = ^TBGRAInt;

const
  DefaultBGRAInt: TBGRAInt = (b: 0; g: 0; r: 0; a: 0);
  DefaultBGRA: TBGRA = (b: 0; g: 0; r: 0; a: 0);

type

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

  TResamplingThreadSetup = record
    Tbps, Sbps: integer; // pitch (bytes per scanline) in Target/Source. Negative for VCL-TBitmap
    ContribsX, ContribsY: TContribArray; // contributors horizontal/vertical
    rStart, rTStart: PByte; // Scanline for row 0
    xmin, xmax: integer;
    ThreadCount: integer;
    xminSource, xmaxSource: integer;
    ymin, ymax: TIntArray; //ymin,ymax for each thread
    CacheMatrix: TCacheMatrix; // Cache for result of vertical pass, 1 array for each thread.
  end;

  PResamplingThreadSetup = ^TResamplingThreadSetup;

  TResamplingThread = class(TThread)
  private
  protected
    procedure Execute; override;
  public
    PRTS: PResamplingThreadSetup;
      Index: integer;
    AlphaCombineMode: TAlphaCombineMode;
    Wakeup, Done, Ready: TEvent;
    procedure RunTask;
    constructor Create;
    destructor Destroy; override;
  end;

  TThreadArray = array of TResamplingThread;

  // A class defining a simple thread pool. Such a class can be
  // passed to the ZoomResampleParallelThreads procedure to indicate that this thread
  // pool should be used. This way the procedure can be used in concurrent threads.
  TResamplingThreadPool = class
  private
    fThreadCount: integer;
    fResamplingThreads: TThreadArray;
  public
    property ResamplingThreads: TThreadArray read fResamplingThreads;
    /// <summary> Creates the threads. Call before you use it in parallel procedures. </summary>
    constructor Create(aMaxThreadCount: integer; aPriority: TThreadpriority);
    /// <summary> Frees the threads. Call when your code exits the part where you use parallel resampling to free up memory and CPU-time.  </summary>
    destructor Destroy; override;
    property ThreadCount: integer read fThreadCount;
  end;


procedure PrepareResamplingThreads(var RTS: TResamplingThreadSetup; NewWidth, NewHeight, OldWidth,
  OldHeight: integer; Radius: single; Filter: TFilter; SourceRect: TFloatRect;
  AlphaCombineMode: TAlphaCombineMode; aMaxThreadCount: integer;
  SourcePitch, TargetPitch: integer; SourceStart, TargetStart: PByte);

var
  _DefaultThreadPool: TResamplingThreadPool;

const
  // constants used to divide the work for threading
  _ChunkHeight: integer = 8;
  _MaxThreadCount: integer = 64;

  /// <summary> Initializes the default resampling thread pool. If already initialized, it does nothing. If not called, the default pool is initialized at the first use of a parallel procedure, causing a delay. </summary>
procedure InitDefaultResamplingThreads;

/// <summary> Frees the default resampling threads. If they are initialized and not finalized the Finalization of uScaleLegacy will do it. </summary>
procedure FinalizeDefaultResamplingThreads;

procedure ProcessRow(y: integer; CacheStart: PBGRAInt;
  const RTS: TResamplingThreadSetup; AlphaCombineMode: TAlphaCombineMode); inline;

procedure RunResamplingTask(const RTS: PResamplingThreadSetup; Index: integer;
  AlphaCombineMode: TAlphaCombineMode);

implementation

type
  TFilterFunction = function(x: double): double;

  TPrecision = (prLow, prHigh);

procedure RunResamplingTask(const RTS: PResamplingThreadSetup; Index: integer;
  AlphaCombineMode: TAlphaCombineMode);
var
  y, ymin, ymax: integer;
  CacheStart: PBGRAInt;
begin
  CacheStart := @RTS^.CacheMatrix[Index][0];
  ymin := RTS.ymin[Index];
  ymax := RTS.ymax[Index];
  for y := ymin to ymax do
  begin
    ProcessRow(y, CacheStart, RTS^, AlphaCombineMode);

  end; // for y
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
  FilterFunctions: array[TFilter] of TFilterFunction = (Box, Linear, Bicubic,
    Mine, Lanczos, BSpline);

  PrecisionFacts: array[TPrecision] of integer = ($100, $800);
  PreMultPrecision = 1 shl 2;

  PointCount = 18; // 6 would be Simpson's rule, but I like emphasis on midpoint
  PointCountMinus2 = PointCount - 2;
  PointCountInv = 1 / PointCount;

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
        x2 := Math.Min(x2, 1);
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
        x2 := Math.Min(x2, 1);
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
        x2 := Math.Min(x2, 1);
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


procedure Combine(const ps: PBGRA; const Weight: integer; const Cache: PBGRAInt;
  const acm: TAlphaCombineMode); inline;
var
  alpha: integer;
begin
  if acm in [amIndependent, amIgnore] then
  begin
    Cache.b := Weight * ps.b;
    Cache.g := Weight * ps.g;
    Cache.r := Weight * ps.r;
    if acm in [amIndependent] then
      Cache.a := Weight * ps.a;
  end
  else
  begin
    if ps.a > 0 then
    begin
      alpha := Weight * ps.a;
      Cache.b := ps.b * alpha div PreMultPrecision;
      Cache.g := ps.g * alpha div PreMultPrecision;
      Cache.r := ps.r * alpha div PreMultPrecision;
      Cache.a := alpha;
    end
    else
      Cache^ := DefaultBGRAInt;
  end;
end;

procedure Increase(const ps: PBGRA; const Weight: integer;
  const Cache: PBGRAInt; const acm: TAlphaCombineMode); inline;
var
  alpha: integer;
begin
  if acm in [amIndependent, amIgnore] then
  begin
    inc(Cache.b, Weight * ps.b);
    inc(Cache.g, Weight * ps.g);
    inc(Cache.r, Weight * ps.r);
    if acm = amIndependent then
      inc(Cache.a, Weight * ps.a);
  end
  else if ps.a > 0 then
  begin
    alpha := Weight * ps.a;
    inc(Cache.b, ps.b * alpha div PreMultPrecision);
    inc(Cache.g, ps.g * alpha div PreMultPrecision);
    inc(Cache.r, ps.r * alpha div PreMultPrecision);
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
    Total := DefaultBGRAInt;
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

procedure ClampIndependent(const Total: TBGRAInt; const pT: PBGRA); inline;
begin
  pT.b := Min((max(Total.b, 0) + $1FFFFF) shr 22, 255);
  pT.g := Min((max(Total.g, 0) + $1FFFFF) shr 22, 255);
  pT.r := Min((max(Total.r, 0) + $1FFFFF) shr 22, 255);
  pT.a := Min((max(Total.a, 0) + $1FFFFF) shr 22, 255);
end;

procedure ClampIgnore(const Total: TBGRAInt; const pT: PBGRA); inline;
begin
  pT.b := Min((max(Total.b, 0) + $1FFFFF) shr 22, 255);
  pT.g := Min((max(Total.g, 0) + $1FFFFF) shr 22, 255);
  pT.r := Min((max(Total.r, 0) + $1FFFFF) shr 22, 255);

end;

procedure ClampPreMult(const Total: TBGRAInt; const pT: PBGRA); inline;
var
  alpha: byte;
begin
  alpha := Min((max(Total.a, 0) + $7FFF) shr 16, 255);
  if alpha > 0 then
  begin
    pT.b := Min((max(Total.b div alpha, 0) + $1FFF) shr 14, 255);
    pT.g := Min((max(Total.g div alpha, 0) + $1FFF) shr 14, 255);
    pT.r := Min((max(Total.r div alpha, 0) + $1FFF) shr 14, 255);
    pT.a := alpha;
  end
  else
    pT^ := DefaultBGRA;
end;

procedure ProcessRow(y: integer; CacheStart: PBGRAInt;
  const RTS: TResamplingThreadSetup; AlphaCombineMode: TAlphaCombineMode); inline;
var
  ps, pT: PBGRA;
  rs, rT: PByte;
  x, i, j: integer;
  highx, highy, minx, miny: integer;
  Weightx, Weighty: PInteger;
  Weight: integer;
  Total: TBGRAInt;
  run: PBGRAInt;
  jump: integer;
begin
  miny := RTS.ContribsY[y].Min;
  highy := RTS.ContribsY[y].High;
  rs := RTS.rStart;
  rT := RTS.rTStart;
  inc(rs, RTS.Sbps * miny);
  inc(rT, RTS.Tbps * y);
  inc(rs, 4 * RTS.xminSource);
  Weighty := @RTS.ContribsY[y].Weights[0];
  ps := PBGRA(rs);
  run := CacheStart;
  Weight := Weighty^;
  //resample vertically into Cache-Array. run points to Cache-Array-Entry.
  //ps is a source-pixel
  for x := RTS.xminSource to RTS.xmaxSource do
  begin

    Combine(ps, Weight, run, AlphaCombineMode);

    inc(ps);
    inc(run);
  end; // for x
  inc(Weighty);
  inc(rs, RTS.Sbps);
  for j := 1 to highy do
  begin
    ps := PBGRA(rs);
    run := CacheStart;
    Weight := Weighty^;
    for x := RTS.xminSource to RTS.xmaxSource do
    begin

      Increase(ps, Weight, run, AlphaCombineMode);

      inc(ps);
      inc(run);
    end; // for x
    inc(Weighty);
    inc(rs, RTS.Sbps);
  end; // for j
  pT := PBGRA(rT);
  inc(pT, RTS.xmin);
  run := CacheStart;
  jump := RTS.xminSource;

  //Resample Cache-array horizontally into target row.
  //Total is the result for one pixel as TBGRAInt.
  for x := RTS.xmin to RTS.xmax do
  begin
    minx := RTS.ContribsX[x].Min;
    highx := RTS.ContribsX[x].High;
    Weightx := @RTS.ContribsX[x].Weights[0];
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

    case AlphaCombineMode of
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
      if pT.a > 128 then
        pT.a := 255
      else
        pT.a := 0;

    inc(pT);
  end; // for x
end;

const
  Precisions: array[TAlphaCombineMode] of TPrecision = (prHigh, prLow,
    prHigh, prLow);

procedure PrepareResamplingThreads(var RTS: TResamplingThreadSetup; NewWidth, NewHeight,
  OldWidth, OldHeight: integer; Radius: single; Filter: TFilter;
  SourceRect: TFloatRect; AlphaCombineMode: TAlphaCombineMode;
  aMaxThreadCount: integer; SourcePitch, TargetPitch: integer;
  SourceStart, TargetStart: PByte);
var
  yChunkCount: integer;
  yChunk: integer;
  j, Index: integer;
begin

  RTS.Tbps := TargetPitch;
  RTS.Sbps := SourcePitch;

  MakeContributors(Radius, OldWidth, NewWidth, SourceRect.Left,
    SourceRect.Right - SourceRect.Left, Filter, Precisions[AlphaCombineMode],
    RTS.ContribsX);
  MakeContributors(Radius, OldHeight, NewHeight, SourceRect.Top,
    SourceRect.Bottom - SourceRect.Top, Filter, Precisions[AlphaCombineMode],
    RTS.ContribsY);

  RTS.rStart := SourceStart; // Source.Scanline[0];
  RTS.rTStart := TargetStart; // Target.Scanline[0];

  yChunkCount := max(Min(NewHeight div _ChunkHeight + 1, aMaxThreadCount), 1);
  RTS.ThreadCount := yChunkCount;

  SetLength(RTS.ymin, RTS.ThreadCount);
  SetLength(RTS.ymax, RTS.ThreadCount);

  yChunk := NewHeight div yChunkCount;

  RTS.xmin := 0;
  RTS.xmax := NewWidth - 1;

  RTS.xminSource := RTS.ContribsX[0].Min;
  RTS.xmaxSource := RTS.ContribsX[RTS.xmax].Min + RTS.ContribsX[RTS.xmax].High;
  for j := 0 to yChunkCount - 1 do
  begin
    RTS.ymin[j] := j * yChunk;
    if j < yChunkCount - 1 then
      RTS.ymax[j] := (j + 1) * yChunk - 1
    else
      RTS.ymax[j] := NewHeight - 1;
  end;

  SetLength(RTS.CacheMatrix, RTS.ThreadCount);
  for Index := 0 to RTS.ThreadCount - 1 do
    SetLength(RTS.CacheMatrix[Index], RTS.xmaxSource - RTS.xminSource + 1);
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
  while not terminated do
  begin
    Ready.SetEvent;
    Wakeup.Waitfor(INFINITE);
    if not terminated then
    begin
      Wakeup.ResetEvent;
      RunResamplingTask(PRTS, Index, AlphaCombineMode);
      Done.SetEvent;
    end;
  end;

end;

procedure TResamplingThread.RunTask;
begin
  Ready.Waitfor(INFINITE);
  Ready.ResetEvent;
  Done.ResetEvent;
  Wakeup.SetEvent;
end;

{ TResamplingThreadPool }

destructor TResamplingThreadPool.Destroy;
var i: integer;
begin
  for i := 0 to Length(fResamplingThreads) - 1 do
  begin
    fResamplingThreads[i].Terminate;
    fResamplingThreads[i].Wakeup.SetEvent;
    fResamplingThreads[i].Free;
    fResamplingThreads[i] := nil;
  end;
  inherited;
end;

function GetNumberOfProcessors: Integer;
var
  si: TSystemInfo; //Windows.pas
begin
  GetSystemInfo({var}si);
  Result := si.dwNumberOfProcessors;
end;

constructor TResamplingThreadPool.Create(aMaxThreadCount: integer;
  aPriority: TThreadpriority);
var i: integer;
begin
  // We need at least 2 threads
  fThreadCount := max(aMaxThreadCount, 2);
  SetLength(fResamplingThreads, fThreadCount);
for i := 0 to Length(ResamplingThreads) - 1 do
  begin
    fResamplingThreads[i] := TResamplingThread.Create;
    fResamplingThreads[i].Priority := aPriority;
    fResamplingThreads[i].Ready.Waitfor(INFINITE);
  end;
end;

procedure InitDefaultResamplingThreads;
begin
  if assigned(_DefaultThreadPool) then
    exit;
  // creating more threads than processors present does not seem to
  // speed up anything.
  _DefaultThreadPool := TResamplingThreadPool.Create(Min(_MaxThreadCount, GetNumberOfProcessors),
    tpHigher);
end;

procedure FinalizeDefaultResamplingThreads;
begin
  _DefaultThreadPool.Free;
  _DefaultThreadPool := nil;
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

