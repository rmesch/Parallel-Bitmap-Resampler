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
  This unit contains types constants and procedures used by both the VCL- and the
  FMX-version of the resampler (uScale and uScaleFMX). If you use any of the uScale*
  units, also add uScaleCommon to the uses clause.
  **************************************************************************** }

unit uScaleCommon;

interface

uses
  System.Types,
  System.UITypes,
  System.Threading,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.SyncObjs;

{$IFOPT O-}
{$DEFINE O_MINUS}
{$O+}
{$ENDIF}
{$IFOPT Q+ }
{$DEFINE Q_PLUS }
{$Q- }
{$ENDIF }
{$WARN SYMBOL_PLATFORM OFF}

type
  // Filter types
  TFilter = (cfBox, cfBilinear, cfBicubic, cfMine, cfLanczos, cfBSpline,
    cfMitchell, cfRobidoux, cfRobidouxSharp, cfRobidouxSoft);

const
  // Default radii for the filters, can be made a tad smaller for performance
  DefaultRadius: array [TFilter] of single = (0.5, 1, 2, 2, 3, 2, 2, 2, 2, 2);

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

type
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

  TThreadArray = array of TResamplingThread;

  // A record defining a simple thread pool. A pointer to such a record can be
  // passed to the ZoomResampleParallelThreads procedure to indicate that this thread
  // pool should be used. This way the procedure can be used in concurrent threads.
  TResamplingThreadPool = record
  private
    fInitialized: boolean;
    fThreadCount: integer;
    fResamplingThreads: TThreadArray;
  public
    property ResamplingThreads: TThreadArray read fResamplingThreads;
    /// <summary> Creates the threads. Call before you use it in parallel procedures. If already initialized, it will finalize first, don't call it unnecessarily. </summary>
    procedure Initialize(aMaxThreadCount: integer; aPriority: TThreadpriority);
    /// <summary> Frees the threads. Call when your code exits the part where you use parallel resampling to free up memory and CPU-time. If you don't finalize a custom threadpool, you will have a memory leak. </summary>
    procedure Finalize;
    property Initialized: boolean read fInitialized;
    property ThreadCount: integer read fThreadCount;
  end;

  PResamplingThreadPool = ^TResamplingThreadPool;

  TBGRA = record
    b, g, r, a: byte;
  end;

  PBGRA = ^TBGRA;

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
    Weights: TIntArray; // floats scaled by $100  or $800
  end;

  TContribArray = array of TContributor;

  TResamplingThreadSetup = record
    Tbps, Sbps: integer;
    // pitch (bytes per scanline) in Target/Source. Negative for VCL-TBitmap
    ContribsX, ContribsY: TContribArray; // contributors horizontal/vertical
    rStart, rTStart: PByte; // Scanline for row 0
    xmin, xmax: integer;
    ThreadCount: integer;
    xminSource, xmaxSource: integer;
    ymin, ymax: TIntArray; // ymin,ymax for each thread
    CacheMatrix: TCacheMatrix;
    // Cache for result of vertical pass, 1 array for each thread.
    procedure PrepareResamplingThreads(NewWidth, NewHeight, OldWidth,
      OldHeight: integer; Radius: single; Filter: TFilter; SourceRect: TRectF;
      AlphaCombineMode: TAlphaCombineMode; aMaxThreadCount: integer;
      SourcePitch, TargetPitch: integer; SourceStart, TargetStart: PByte);
  end;

  PResamplingThreadSetup = ^TResamplingThreadSetup;

var
  _DefaultThreadPool: TResamplingThreadPool;
  _IsFMX: boolean; // value is set in initialization of uScale and uScaleFMX

const
  // constants used to divide the work for threading
  _ChunkHeight: integer = 8;
  _MaxThreadCount: integer = 64;

  /// <summary> Initializes the default resampling thread pool. If already initialized, it does nothing. If not called, the default pool is initialized at the first use of a parallel procedure, causing a delay. </summary>
procedure InitDefaultResamplingThreads;

/// <summary> Frees the default resampling threads. If they are initialized and not finalized the Finalization of uScale(FMX) will do it. </summary>
procedure FinalizeDefaultResamplingThreads;

procedure ProcessRow(y: integer; CacheStart: PBGRAInt;
  const RTS: TResamplingThreadSetup;
  AlphaCombineMode: TAlphaCombineMode); inline;

procedure MakeGaussContributors(r, fact: single; SourceSize: integer;
  var Contribs: TContribArray);

procedure ProcessRowUnsharp(y, bps, xmin, xmax, alphaInt, sig: integer;
  Thresh: single; rStart, rTStart: PByte; runstart: PBGRAInt;
  const ContribsX: TContribArray; const yContrib: TContributor;
  Acm: TAlphaCombineMode); inline;

procedure ProcessRowUnsharpGamma(y, bps, xmin, xmax, alphaInt, sig: integer;
  Thresh: single; rStart, rTStart: PByte; runstart: PBGRAInt;
  const ContribsX: TContribArray; const yContrib: TContributor;
  Acm: TAlphaCombineMode); inline;

// constants for scaling and unscaling the Gauss-weights
const
  GaussPrecision = 10;
  GaussScale = 1 shl GaussPrecision;
  GaussShift = 2 * GaussPrecision;
  GaussRound = (1 shl GaussShift) div 2 - 1;
  GaussShiftAlpha = GaussShift - 8;
  GaussRoundAlpha = (1 shl GaussShiftAlpha) div 2 - 1;

type
  TGammaTable8Bit = array [byte] of byte;
  TGammaTable10Bit = array [byte] of word;

var
  GammaEncodingTable: TGammaTable8Bit;
  GammaDecodingTable: TGammaTable10Bit;

procedure MakeGammaTables(gamma: double);

implementation

const
  ByteScale = 1 / 255;

procedure MakeGammaTables(gamma: double);
var
  b: byte;
  gammaInv: double;
begin
  gammaInv := 1 / gamma;
  for b := 0 to $FF do
  begin
    GammaDecodingTable[b] := round($3FF * Power(b * ByteScale, gamma));
    GammaEncodingTable[b] := round($FF * Power(b * ByteScale, gammaInv));
  end;
end;

type
  TFilterFunction = function(x: double): double;

  TPrecision = (prLow, prHigh);

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
  Alpha = 105 / (16 - 112 * beta2);
  aa = 1 / 7 * Alpha;
  bb = -1 / 5 * Alpha * (2 + beta2);
  cc = 1 / 3 * Alpha * (1 + 2 * beta2);
  dd = -Alpha * beta2;

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

// The following filters are based on the Mitchell-Netravali filters with
// restricting the parameters B and C to the "good" line B + 2*C = 1.
// We have eliminated B this way and scaled the filter to [-1,1].
// See https://en.wikipedia.org/wiki/Mitchell%E2%80%93Netravali_filters
// Thanks to Kas Ob. for suggesting them in https://en.delphipraxis.net/
const
  C_M = 1 / 3;

  // Mitchell filter used by ImageMagick
function Mitchell(x: double): double; inline;
begin
  x := abs(x);
  if x < 0.5 then
    Result := (8 + 32 * C_M) * x * x * x - (8 + 24 * C_M) * x * x + 4 / 3 +
      4 / 3 * C_M
  else if x < 1 then
    Result := -(8 / 3 + 32 / 3 * C_M) * x * x * x + (8 + 24 * C_M) * x * x -
      (8 + 16 * C_M) * x + 8 / 3 + 8 / 3 * C_M
  else
    Result := 0;
end;

const
  C_R = 0.3109;

  // Robidoux filter
function Robidoux(x: double): double; inline;
begin
  x := abs(x);
  if x < 0.5 then
    Result := (8 + 32 * C_R) * x * x * x - (8 + 24 * C_R) * x * x + 4 / 3 +
      4 / 3 * C_R
  else if x < 1 then
    Result := -(8 / 3 + 32 / 3 * C_R) * x * x * x + (8 + 24 * C_R) * x * x -
      (8 + 16 * C_R) * x + 8 / 3 + 8 / 3 * C_R
  else
    Result := 0;
end;

const
  C_RS = 0.3690;

  // Robidoux-Sharp filter
function RobidouxSharp(x: double): double; inline;
begin
  x := abs(x);
  if x < 0.5 then
    Result := (8 + 32 * C_RS) * x * x * x - (8 + 24 * C_RS) * x * x + 4 / 3 + 4
      / 3 * C_RS
  else if x < 1 then
    Result := -(8 / 3 + 32 / 3 * C_RS) * x * x * x + (8 + 24 * C_RS) * x * x -
      (8 + 16 * C_RS) * x + 8 / 3 + 8 / 3 * C_RS
  else
    Result := 0;
end;

const
  C_RD = 0.1602;

  // Robidoux-Soft filter
function RobidouxSoft(x: double): double; inline;
begin
  x := abs(x);
  if x < 0.5 then
    Result := (8 + 32 * C_RD) * x * x * x - (8 + 24 * C_RD) * x * x + 4 / 3 + 4
      / 3 * C_RD
  else if x < 1 then
    Result := -(8 / 3 + 32 / 3 * C_RD) * x * x * x + (8 + 24 * C_RD) * x * x -
      (8 + 16 * C_RD) * x + 8 / 3 + 8 / 3 * C_RD
  else
    Result := 0;
end;

const
  FilterFunctions: array [TFilter] of TFilterFunction = (Box, Linear, Bicubic,
    Mine, Lanczos, BSpline, Mitchell, Robidoux, RobidouxSharp, RobidouxSoft);

  PrecisionFacts: array [TPrecision] of integer = ($100, $800);
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

procedure Combine(const ps: PBGRA; const Weight: integer; const Cache: PBGRAInt;
  const Acm: TAlphaCombineMode); inline;
var
  Alpha: integer;
begin
  if Acm in [amIndependent, amIgnore] then
  begin
    Cache.b := Weight * ps.b;
    Cache.g := Weight * ps.g;
    Cache.r := Weight * ps.r;
    if Acm in [amIndependent] then
      Cache.a := Weight * ps.a;
  end
  else
  begin
    if ps.a > 0 then
    begin
      Alpha := Weight * ps.a;
      Cache.b := ps.b * Alpha div PreMultPrecision;
      Cache.g := ps.g * Alpha div PreMultPrecision;
      Cache.r := ps.r * Alpha div PreMultPrecision;
      Cache.a := Alpha;
    end
    else
      Cache^ := Default (TBGRAInt);
  end;
end;

procedure Increase(const ps: PBGRA; const Weight: integer;
  const Cache: PBGRAInt; const Acm: TAlphaCombineMode); inline;
var
  Alpha: integer;
begin
  if Acm in [amIndependent, amIgnore] then
  begin
    inc(Cache.b, Weight * ps.b);
    inc(Cache.g, Weight * ps.g);
    inc(Cache.r, Weight * ps.r);
    if Acm = amIndependent then
      inc(Cache.a, Weight * ps.a);
  end
  else if ps.a > 0 then
  begin
    Alpha := Weight * ps.a;
    inc(Cache.b, ps.b * Alpha div PreMultPrecision);
    inc(Cache.g, ps.g * Alpha div PreMultPrecision);
    inc(Cache.r, ps.r * Alpha div PreMultPrecision);
    inc(Cache.a, Alpha);
  end;
end;

procedure InitTotal(const Cache: PBGRAInt; const Weight: integer;
  var Total: TBGRAInt; const Acm: TAlphaCombineMode); inline;
begin
  if Acm in [amIndependent, amIgnore] then
  begin
    Total.b := Weight * Cache.b;
    Total.g := Weight * Cache.g;
    Total.r := Weight * Cache.r;
    if Acm = amIndependent then
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
  var Total: TBGRAInt; const Acm: TAlphaCombineMode); inline;
begin
  if Acm in [amIndependent, amIgnore] then
  begin
    inc(Total.b, Weight * Cache.b);
    inc(Total.g, Weight * Cache.g);
    inc(Total.r, Weight * Cache.r);
    if Acm = amIndependent then
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
  if _IsFMX then
    pT.a := 255;
end;

procedure ClampPreMult(const Total: TBGRAInt; const pT: PBGRA); inline;
var
  Alpha: byte;
begin
  Alpha := Min((max(Total.a, 0) + $7FFF) shr 16, 255);
  if Alpha > 0 then
  begin
    pT.b := Min((max(Total.b div Alpha, 0) + $1FFF) shr 14, 255);
    pT.g := Min((max(Total.g div Alpha, 0) + $1FFF) shr 14, 255);
    pT.r := Min((max(Total.r div Alpha, 0) + $1FFF) shr 14, 255);
    pT.a := Alpha;
  end
  else
    pT^ := Default (TBGRA);
end;

procedure ProcessRow(y: integer; CacheStart: PBGRAInt;
  const RTS: TResamplingThreadSetup;
  AlphaCombineMode: TAlphaCombineMode); inline;
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
  // resample vertically into Cache-Array. run points to Cache-Array-Entry.
  // ps is a source-pixel
  // for x := RTS.xminSource to RTS.xmaxSource do
  x := RTS.xmaxSource - RTS.xminSource + 1;
  while x > 0 do
  begin

    Combine(ps, Weight, run, AlphaCombineMode);

    inc(ps);
    inc(run);
    dec(x);
  end; // for x
  inc(Weighty);
  inc(rs, RTS.Sbps);
  for j := 1 to highy do
  begin
    ps := PBGRA(rs);
    run := CacheStart;
    Weight := Weighty^;
    // for x := RTS.xminSource to RTS.xmaxSource do
    x := RTS.xmaxSource - RTS.xminSource + 1;
    while x > 0 do
    begin

      Increase(ps, Weight, run, AlphaCombineMode);

      inc(ps);
      inc(run);
      dec(x);
    end; // for x
    inc(Weighty);
    inc(rs, RTS.Sbps);
  end; // for j
  pT := PBGRA(rT);
  inc(pT, RTS.xmin);
  run := CacheStart;
  jump := RTS.xminSource;

  // Resample Cache-array horizontally into target row.
  // Total is the result for one pixel as TBGRAInt.
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
      if pT.a > 128 then
        pT.a := 255
      else
        pT.a := 0;

    inc(pT);
  end; // for x
end;

const
  Precisions: array [TAlphaCombineMode] of TPrecision = (prHigh, prLow,
    prHigh, prLow);

procedure TResamplingThreadSetup.PrepareResamplingThreads(NewWidth, NewHeight,
  OldWidth, OldHeight: integer; Radius: single; Filter: TFilter;
  SourceRect: TRectF; AlphaCombineMode: TAlphaCombineMode;
  aMaxThreadCount: integer; SourcePitch, TargetPitch: integer;
  SourceStart, TargetStart: PByte);
var
  yChunkCount: integer;
  yChunk: integer;
  j, Index: integer;
begin

  Tbps := TargetPitch;
  Sbps := SourcePitch;

  MakeContributors(Radius, OldWidth, NewWidth, SourceRect.Left,
    SourceRect.Right - SourceRect.Left, Filter, Precisions[AlphaCombineMode],
    ContribsX);
  MakeContributors(Radius, OldHeight, NewHeight, SourceRect.Top,
    SourceRect.Bottom - SourceRect.Top, Filter, Precisions[AlphaCombineMode],
    ContribsY);

  rStart := SourceStart; // Source.Scanline[0];
  rTStart := TargetStart; // Target.Scanline[0];

  yChunkCount := max(Min(NewHeight div _ChunkHeight + 1, aMaxThreadCount), 1);
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
var
  i: integer;
begin
  if not Initialized then
    exit;
  for i := 0 to Length(fResamplingThreads) - 1 do
  begin
    fResamplingThreads[i].Terminate;
    fResamplingThreads[i].Wakeup.SetEvent;
    fResamplingThreads[i].Free;
    fResamplingThreads[i] := nil;
  end;
  SetLength(fResamplingThreads, 0);
  fThreadCount := 0;
  fInitialized := false;
end;

procedure TResamplingThreadPool.Initialize(aMaxThreadCount: integer;
  aPriority: TThreadpriority);
var i: integer;
begin
  if Initialized then
    Finalize;
  // We need at least 2 threads
  fThreadCount := max(aMaxThreadCount, 2);
  SetLength(fResamplingThreads, fThreadCount);

  for i := 0 to Length(ResamplingThreads) - 1 do
  begin
    fResamplingThreads[i] := TResamplingThread.Create;
    fResamplingThreads[i].Priority := aPriority;
    fResamplingThreads[i].Ready.Waitfor(INFINITE);
  end;
  fInitialized := true;
end;

procedure InitDefaultResamplingThreads;
begin
  if _DefaultThreadPool.fInitialized then
    exit;
  // creating more threads than processors present does not seem to
  // speed up anything. Leave 1 processor for system.
  _DefaultThreadPool.Initialize(Min(_MaxThreadCount, TThread.ProcessorCount -
    1), tpHigher);
end;

procedure FinalizeDefaultResamplingThreads;
begin
  if not _DefaultThreadPool.fInitialized then
    exit;
  _DefaultThreadPool.Finalize;
end;

// Follows the code for the Unsharp-Mask:

const
  // with this value Gauss(1)=0.01*Gauss(0).
  // when Gauss is scaled to an interval [-r,r]
  // via Gauss_r(x) = 1/r*Gauss(1/r*x), the
  // sigma of Gauss_r is sigma_r = r/sigmaInv appr. = 0.33*r.
  sigmaInv = 3.0348542587702927017259447870998;
  // sigmaInv = 2.14596602628934723963618357029; //O.1*Gauss(0)
  // sigmaInv=3.7169221888498384469524067613045; //0.001*Gauss(0) fact=0.27
  sigma = 1 / sigmaInv;
  // sigma = 0.424660891294479;
  // sigmaInv = 1 / sigma;

function Gauss(x: double): double; inline;
begin
  if x < 0 then
  begin
    Result := Gauss(-x);
    exit;
  end;
  if x > 1 then
    Result := 0
  else
  begin
    // scale := sigmaInv / Sqrt(2 * Pi);
    // no need to multiply by scale, weights get normalized anyway.
    Result := exp(-1 / 2 * x * x * sigmaInv * sigmaInv);
  end;
end;

// Simpson's rule. Assumes x1 < x2.
function GaussIntegral(x1, x2: double): double; inline;
var
  xmid: double;
begin
  if (x2 < -1) or (x1 > 1) then
  begin
    Result := 0;
    exit;
  end;
  // intersect with support
  x1 := max(x1, -1);
  x2 := Min(x2, 1);
  xmid := 0.5 * (x1 + x2);
  Result := 1 / 6 * (x2 - x1) * (Gauss(x1) + Gauss(x2) + 4 * Gauss(xmid));
  // Result:=(x2-x1)*Gauss(xmid);
end;

type
  TDoublearray = array of double;



  // r is the radius of the unsharp-mask, corresponding to sigma=r/SigmaInv for the Gauss-kernel
  // scaled to [-r,r].

  // fact is sqrt(abs(1-alpha)), where for the sharpening
  // ResultPixel:=alpha*SourcePixel + (1-alpha)*Gaussian-Blur
  // Because the blur is applied horizontally and vertically, the square-root
  // needs to enter in the weights.
  // We include the factor in the weights so we can scale everything to integer,
  // and need not compute in the float range.
  // For sharpening alpha needs to be >1. Alpha<1 blurs, alpha=0 is Gaussian blur.
procedure MakeGaussContributors(r, fact: single; SourceSize: integer;
  var Contribs: TContribArray);

var
  xCenter: double;
  x, j, sumInt: integer;
  x1, x2, delta: double;
  TrueMin, TrueMax, Mx: integer;
  RealWeights: TDoublearray;
  StandardWeights: TIntArray;
  sum, scale, dw: double;
  IntCorrection: integer;
begin
  SetLength(Contribs, SourceSize);
  // First we compute StandardWeights for the blur,
  // the weights to be applied when [x-r,x+r]
  // does not intersect the image-boundary.
  delta := 1 / r;
  xCenter := 0.5;
  TrueMin := Ceil(xCenter - r - 1);
  TrueMax := Floor(xCenter + r);
  SetLength(RealWeights, TrueMax - TrueMin + 1);
  x1 := delta * (TrueMin - xCenter);
  sum := 0;
  for j := 0 to TrueMax - TrueMin do
  begin
    x2 := x1 + delta;
    RealWeights[j] := GaussIntegral(x1, x2);
    x1 := x2;
    sum := sum + RealWeights[j];
  end;
  if sum = 0 then
    // never happens
    scale := 1
  else
    scale := 1 / sum;
  // RealWeights need to be mulitplied by 1/sum,
  // so they add up to 1.
  // StandardWeights are scaled to integer by GaussScale (currently $400).
  // The factor fact=sqrt(abs(1-alpha)) is multiplied in.
  // As a result the StandardWeights sum up to
  // approximately GaussScale*fact.
  // When applied horizontally and vertically, weights sum up
  // to GaussScale*GaussScale*abs(1-alpha).
  SetLength(StandardWeights, Length(RealWeights));
  sumInt := 0;
  for j := 0 to Length(StandardWeights) - 1 do
  begin
    StandardWeights[j] := round(fact * scale * RealWeights[j] * GaussScale);
    inc(sumInt, StandardWeights[j]);
  end;
  // Make sure the integer-scaled weights sum up to integer-scaled abs(1-alpha)
  IntCorrection := round(fact * GaussScale) - sumInt;
  inc(StandardWeights[(TrueMax - TrueMin + 1) div 2], IntCorrection);

  for x := 0 to SourceSize - 1 do
  begin
    xCenter := (x + 0.5);
    TrueMin := Ceil(xCenter - r - 1);
    TrueMax := Floor(xCenter + r);
    Contribs[x].Min := Min(max(TrueMin, 0), SourceSize - 1);
    // make sure not to read in negative pixel locations
    Mx := max(Min(TrueMax, SourceSize - 1), 0);
    // make sure not to read past w1-1 in the source
    Contribs[x].High := Mx - Contribs[x].Min;
    Assert(Contribs[x].High >= 0);

    if Contribs[x].High = Length(StandardWeights) - 1 then
      // radius-interval does not intersect boundary
      Contribs[x].Weights := StandardWeights
    else
    // radius-interval intersects boundary. Assume
    // boundary-pixels to be mirrored.
    begin
      SetLength(Contribs[x].Weights, Contribs[x].High + 1);
      for j := 0 to Contribs[x].High do
        Contribs[x].Weights[j] := StandardWeights
          [j + Contribs[x].Min - TrueMin];
      for j := TrueMin - Contribs[x].Min to -1 do
        // mirror bitmap at first pixel
        inc(Contribs[x].Weights[-j],
          StandardWeights[j + Contribs[x].Min - TrueMin]);
      for j := Contribs[x].High + 1 to TrueMax - Contribs[x].Min do
        // mirror bitmap at last pixel
        inc(Contribs[x].Weights[2 * Contribs[x].High - j],
          StandardWeights[j + Contribs[x].Min - TrueMin]);
    end;
  end; { for x }
end;

procedure ProcessRowUnsharp(y, bps, xmin, xmax, alphaInt, sig: integer;
  Thresh: single; rStart, rTStart: PByte; runstart: PBGRAInt;
  const ContribsX: TContribArray; const yContrib: TContributor;
  Acm: TAlphaCombineMode);
var
  ps, pT: PBGRA;
  rs, rT: PByte;
  x, i, j: integer;
  highx, highy, minx, miny: integer;
  Weightx, Weighty: PInteger;
  Weight: integer;
  Total: TBGRAInt;
  run: PBGRAInt;
  delta, scale: integer;
  threshInt: integer;
  DoApply: boolean;
  jump: integer;
  Alpha: byte;
begin
  // scaled abs(1-alpha):
  scale := abs(GaussScale * GaussScale - alphaInt);

  // scales Thresh*255 by GaussScale*GaussScale*abs(1-alpha),
  // which is the sum of the Gauss-Weights.
  // Needed to scale the difference of SourcePixel-Blur
  // to the right order of magnitude.
  threshInt := round(scale * Thresh * 255);

  // Apply Blur-Weights vertically,
  // Store results in Cache-Array.
  // run walks along the Cache-Array.
  miny := yContrib.Min;
  highy := yContrib.High;
  rs := rStart;
  rT := rTStart;
  inc(rs, bps * miny);
  inc(rT, bps * y);
  inc(rs, 4 * xmin);
  Weighty := @yContrib.Weights[0];
  ps := PBGRA(rs);
  run := runstart;
  Weight := Weighty^;
  x := xmax - xmin + 1;
  while x > 0 do
  begin
    if Acm in [amIgnore, amIndependent] then
    begin
      run.b := Weight * ps.b;
      run.g := Weight * ps.g;
      run.r := Weight * ps.r;
      if Acm = amIndependent then
        run.a := Weight * ps.a;
    end
    else
    begin
      run.b := (Weight * ps.b * ps.a) shr 8;
      run.g := (Weight * ps.g * ps.a) shr 8;
      run.r := (Weight * ps.r * ps.a) shr 8;
      run.a := Weight * ps.a;
    end;
    inc(ps);
    inc(run);
    dec(x);
  end; // for x
  inc(Weighty);
  inc(rs, bps);
  for j := 1 to highy do
  begin
    ps := PBGRA(rs);
    run := runstart;
    Weight := Weighty^;
    x := xmax - xmin + 1;
    while x > 0 do
    begin
      if Acm in [amIgnore, amIndependent] then
      begin
        inc(run.b, Weight * ps.b);
        inc(run.g, Weight * ps.g);
        inc(run.r, Weight * ps.r);
        if Acm = amIndependent then
          inc(run.a, Weight * ps.a);
      end
      else if ps.a > 0 then
      begin
        inc(run.b, (Weight * ps.b * ps.a) shr 8);
        inc(run.g, (Weight * ps.g * ps.a) shr 8);
        inc(run.r, (Weight * ps.r * ps.a) shr 8);
        inc(run.a, Weight * ps.a);
      end;
      inc(ps);
      inc(run);
      dec(x);
    end; // for x
    inc(Weighty);
    inc(rs, bps);
  end; // for j

  pT := PBGRA(rT);
  rs := rStart;
  inc(rs, bps * y);
  ps := PBGRA(rs);
  inc(ps, xmin);
  inc(pT, xmin);
  // ps and pT now need to be at the same location to do the sharpening
  run := runstart;
  jump := xmin;
  for x := xmin to xmax do
  begin
    // Apply blur-weights horizontally to CacheArray,
    // store result in Total. Total is (scaled) blur at x.
    minx := ContribsX[x].Min;
    highx := ContribsX[x].High;
    Weightx := @ContribsX[x].Weights[0];
    inc(run, minx - jump);
    Weight := Weightx^;
    Total.b := Weight * run.b;
    Total.g := Weight * run.g;
    Total.r := Weight * run.r;
    if Acm <> amIgnore then
      Total.a := Weight * run.a;

    inc(Weightx);
    inc(run);
    for i := 1 to highx do
    begin

      Weight := Weightx^;
      inc(Total.b, Weight * run.b);
      inc(Total.g, Weight * run.g);
      inc(Total.r, Weight * run.r);
      if Acm <> amIgnore then
        inc(Total.a, Weight * run.a);

      inc(Weightx);
      inc(run);
    end;
    jump := highx + 1 + minx;

    // Total now holds the values for GaussScale*GaussScale*abs(1-alpha)*Blur

    // Scale ps to this order of magnitude so the threshhold
    // can be checked correctly.
    delta := max(max(abs(Total.r - scale * ps.r), abs(Total.b - scale * ps.b)),
      abs(Total.g - scale * ps.g));
    DoApply := delta > threshInt;
    if DoApply then
    begin
      // if alpha > 1 the blur needs to be subtracted (sig=-1),
      // otherwise added (sig=1).
      Total.b := sig * Total.b + alphaInt * ps.b;
      Total.g := sig * Total.g + alphaInt * ps.g;
      Total.r := sig * Total.r + alphaInt * ps.r;
      if Acm <> amIgnore then
        Total.a := sig * Total.a + alphaInt * ps.a;
      if Acm in [amIgnore, amIndependent] then
      begin
        pT.b := Min((max(Total.b, 0) + GaussRound) shr GaussShift, 255);
        pT.g := Min((max(Total.g, 0) + GaussRound) shr GaussShift, 255);
        pT.r := Min((max(Total.r, 0) + GaussRound) shr GaussShift, 255);
        if Acm = amIndependent then
          pT.a := Min((max(Total.a, 0) + GaussRound) shr GaussShift, 255);
      end
      else
      begin
        Alpha := Min((max(Total.a, 0) + GaussRound) shr GaussShift, 255);
        if Alpha = 0 then
          pT^ := Default (TBGRA)
        else
        begin
          pT.b := Min((max(Total.b div Alpha, 0) + GaussRoundAlpha)
            shr GaussShiftAlpha, 255);
          pT.g := Min((max(Total.g div Alpha, 0) + GaussRoundAlpha)
            shr GaussShiftAlpha, 255);
          pT.r := Min((max(Total.r div Alpha, 0) + GaussRoundAlpha)
            shr GaussShiftAlpha, 255);
          pT.a := Alpha;
        end;
      end;
    end
    else
      pT^ := ps^;
    inc(pT);
    inc(ps);
  end; // for x
end;

procedure ProcessRowUnsharpGamma(y, bps, xmin, xmax, alphaInt, sig: integer;
  Thresh: single; rStart, rTStart: PByte; runstart: PBGRAInt;
  const ContribsX: TContribArray; const yContrib: TContributor;
  Acm: TAlphaCombineMode);
var
  ps, pT: PBGRA;
  rs, rT: PByte;
  x, i, j: integer;
  highx, highy, minx, miny: integer;
  Weightx, Weighty: PInteger;
  Weight: integer;
  Total: TBGRAInt;
  run: PBGRAInt;
  delta, scale: integer;
  threshInt: integer;
  DoApply: boolean;
  jump: integer;
  Alpha: byte;
  AlphaGamma, ScaleGamma: integer;
  psScaled: TBGRAInt;
begin
  // scaled abs(1-alpha):
  scale := abs(GaussScale * GaussScale - alphaInt);

  // scales Thresh*255 by GaussScale*GaussScale*abs(1-alpha),
  // which is the sum of the Gauss-Weights.
  // Needed to scale the difference of SourcePixel-Blur
  // to the right order of magnitude.
  threshInt := round(scale * Thresh * 255);

  AlphaGamma := alphaInt div 4;
  ScaleGamma := scale shr 2;

  // Apply Blur-Weights vertically,
  // Store results in Cache-Array.
  // run walks along the Cache-Array.
  miny := yContrib.Min;
  highy := yContrib.High;
  rs := rStart;
  rT := rTStart;
  inc(rs, bps * miny);
  inc(rT, bps * y);
  inc(rs, 4 * xmin);
  Weighty := @yContrib.Weights[0];
  ps := PBGRA(rs);
  run := runstart;
  Weight := Weighty^;
  x := xmax - xmin + 1;
  while x > 0 do
  begin
    if Acm in [amIgnore, amIndependent] then
    begin
      run.b := (Weight * GammaDecodingTable[ps.b]) shr 2;
      run.g := (Weight * GammaDecodingTable[ps.g]) shr 2;
      run.r := (Weight * GammaDecodingTable[ps.r]) shr 2;
      if Acm = amIndependent then
        run.a := Weight * ps.a;
    end
    else
    begin
      run.b := (Weight * GammaDecodingTable[ps.b] * ps.a) shr 10;
      run.g := (Weight * GammaDecodingTable[ps.g] * ps.a) shr 10;
      run.r := (Weight * GammaDecodingTable[ps.r] * ps.a) shr 10;
      run.a := Weight * ps.a;
    end;
    inc(ps);
    inc(run);
    dec(x);
  end; // for x
  inc(Weighty);
  inc(rs, bps);
  for j := 1 to highy do
  begin
    ps := PBGRA(rs);
    run := runstart;
    Weight := Weighty^;
    x := xmax - xmin + 1;
    while x > 0 do
    begin
      if Acm in [amIgnore, amIndependent] then
      begin
        inc(run.b, (Weight * GammaDecodingTable[ps.b]) shr 2);
        inc(run.g, (Weight * GammaDecodingTable[ps.g]) shr 2);
        inc(run.r, (Weight * GammaDecodingTable[ps.r]) shr 2);
        if Acm = amIndependent then
          inc(run.a, Weight * ps.a);
      end
      else if ps.a > 0 then
      begin
        inc(run.b, (Weight * GammaDecodingTable[ps.b] * ps.a) shr 10);
        inc(run.g, (Weight * GammaDecodingTable[ps.g] * ps.a) shr 10);
        inc(run.r, (Weight * GammaDecodingTable[ps.r] * ps.a) shr 10);
        inc(run.a, Weight * ps.a);
      end;
      inc(ps);
      inc(run);
      dec(x);
    end; // for x
    inc(Weighty);
    inc(rs, bps);
  end; // for j

  pT := PBGRA(rT);
  rs := rStart;
  inc(rs, bps * y);
  ps := PBGRA(rs);
  inc(ps, xmin);
  inc(pT, xmin);
  // ps and pT now need to be at the same location to do the sharpening
  run := runstart;
  jump := xmin;
  for x := xmin to xmax do
  begin
    // Apply blur-weights horizontally to CacheArray,
    // store result in Total. Total is (scaled) blur at x.
    minx := ContribsX[x].Min;
    highx := ContribsX[x].High;
    Weightx := @ContribsX[x].Weights[0];
    inc(run, minx - jump);
    Weight := Weightx^;
    Total.b := Weight * run.b;
    Total.g := Weight * run.g;
    Total.r := Weight * run.r;
    if Acm <> amIgnore then
      Total.a := Weight * run.a;

    inc(Weightx);
    inc(run);
    for i := 1 to highx do
    begin

      Weight := Weightx^;
      inc(Total.b, Weight * run.b);
      inc(Total.g, Weight * run.g);
      inc(Total.r, Weight * run.r);
      if Acm <> amIgnore then
        inc(Total.a, Weight * run.a);

      inc(Weightx);
      inc(run);
    end;
    jump := highx + 1 + minx;

    // Total now holds the values for GaussScale*GaussScale*abs(1-alpha)*Blur

    // Scale ps to this order of magnitude so the threshhold
    // can be checked correctly.
    psScaled.b := (scale * GammaDecodingTable[ps.b]) shr 2;
    psScaled.g := (scale * GammaDecodingTable[ps.g]) shr 2;
    psScaled.r := (scale * GammaDecodingTable[ps.r]) shr 2;
    delta := max(max(abs(Total.r - psScaled.r), abs(Total.b - psScaled.b)),
      abs(Total.g - psScaled.g));
    DoApply := delta > threshInt;
    if DoApply then
    begin
      // if alpha > 1 the blur needs to be subtracted (sig=-1),
      // otherwise added (sig=1).
      Total.b := sig * Total.b + AlphaGamma * GammaDecodingTable[ps.b];
      Total.g := sig * Total.g + AlphaGamma * GammaDecodingTable[ps.g];
      Total.r := sig * Total.r + AlphaGamma * GammaDecodingTable[ps.r];
      if Acm <> amIgnore then
        Total.a := sig * Total.a + alphaInt * ps.a;
      if Acm in [amIgnore, amIndependent] then
      begin
        pT.b := Min((max(Total.b, 0) + GaussRound) shr GaussShift, 255);
        pT.g := Min((max(Total.g, 0) + GaussRound) shr GaussShift, 255);
        pT.r := Min((max(Total.r, 0) + GaussRound) shr GaussShift, 255);
        if Acm = amIndependent then
          pT.a := Min((max(Total.a, 0) + GaussRound) shr GaussShift, 255);
      end
      else
      begin
        Alpha := Min((max(Total.a, 0) + GaussRound) shr GaussShift, 255);
        if Alpha = 0 then
          pT^ := Default (TBGRA)
        else
        begin
          pT.b := Min((max(Total.b div Alpha, 0) + GaussRoundAlpha)
            shr GaussShiftAlpha, 255);
          pT.g := Min((max(Total.g div Alpha, 0) + GaussRoundAlpha)
            shr GaussShiftAlpha, 255);
          pT.r := Min((max(Total.r div Alpha, 0) + GaussRoundAlpha)
            shr GaussShiftAlpha, 255);
          pT.a := Alpha;
        end;
      end;
      pT.b := GammaEncodingTable[pT.b];
      pT.g := GammaEncodingTable[pT.g];
      pT.r := GammaEncodingTable[pT.r];
    end
    else
      pT^ := ps^;
    inc(pT);
    inc(ps);
  end; // for x
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
