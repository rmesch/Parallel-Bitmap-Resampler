unit uZoomPanFMXMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation, FMX.ListBox;

type
  TZoomPanFMXMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    GroupBox1: TGroupBox;
    Make: TButton;
    GroupBox2: TGroupBox;
    Load: TButton;
    OD: TOpenDialog;
    Panel5: TPanel;
    GroupBox3: TGroupBox;
    Heights: TComboBox;
    Panel6: TPanel;
    MovieRect: TRectangle;
    MovieBox: TPaintBox;
    Start: TButton;
    Filter: TComboBox;
    Scaling: TComboBox;
    FPS: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure MakeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MovieBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure HeightsChange(Sender: TObject);
    procedure MovieRectResize(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
  private
    TheSource, MovieBm, AniBm: TBitmap;
    Aspect: double;
    MovieWidth, MovieHeight: integer;
    procedure MakeTestBitmap;
    procedure UpdatePositions;
    function GetScreenScale: single;
    function GetScreenScaleInv: single;
    procedure FMXScaling(t: double);
    procedure uScaleScaling(t: double);
    { Private-Deklarationen }
  public
    property ScreenScale: single read GetScreenScale;
    property ScreenScaleInv: single read GetScreenScaleInv;
    { Public-Deklarationen }
  end;

var
  ZoomPanFMXMain: TZoomPanFMXMain;

implementation

{$R *.fmx}

uses uTestBitmap, uToolsFMX, uScaleFMX, uScaleCommon, System.Diagnostics;

type
  // Defines a normalized zoom-zectangle [xcenter-radius,xcenter+radius]x[ycenter-radius,ycenter+radius]
  // as a sub-rectangle of [0,1]x[0,1]
  // when multiplied by the width/height of a bitmap it defines an aspect-preserving sub-rectangle of
  // the bitmap.
  TZoomPan = record
    xcenter, ycenter, Radius: double;
    procedure Define(xc, yc, r: double); inline;
  end;

function ZoomPanToFloatrect(zp: TZoomPan; w, h: integer): TRectF; inline;
begin
  result.Left := (zp.xcenter - zp.Radius) * w;
  result.Top := (zp.ycenter - zp.Radius) * h;
  result.Right := (zp.xcenter + zp.Radius) * w;
  result.Bottom := (zp.ycenter + zp.Radius) * h;
end;

function Interpolate(AStart, AEnd: TZoomPan; t: double): TZoomPan; inline;
begin
  result.xcenter := AStart.xcenter + t * (AEnd.xcenter - AStart.xcenter);
  result.ycenter := AStart.ycenter + t * (AEnd.ycenter - AStart.ycenter);
  result.Radius := AStart.Radius + t * (AEnd.Radius - AStart.Radius);
end;

procedure TZoomPan.Define(xc, yc, r: double);
begin
  xcenter := xc;
  ycenter := yc;
  Radius := r;
end;

function StartSlowEndSlow(t: double): double; inline;
begin
  if t<0.5 then
  result:=2*sqr(t)
  else
  result:=1-2*sqr(1-t);
end;

// pan from bottom-left to top-right
// followed by zoom-out to full image
// t runs from 0 to 1
function Animation(t: double): TZoomPan; inline;
var
  Start, mid, dst: TZoomPan;
begin
  Start.Define(0.4, 0.6, 0.4);
  mid.Define(0.75, 0.5, 0.25);
  dst.Define(0.5, 0.5, 0.5);
  if t < 0.5 then
  begin
    result := Interpolate(Start, mid, StartSlowEndSlow(2*t));
  end
  else
  begin
    result := Interpolate(mid, dst, StartSlowEndSlow(2*(t-0.5)));
  end;
end;

const
  MovieHeights: array [0 .. 6] of integer = (360, 480, 600, 720, 900,
    1080, 1440);
  Filters: array [0 .. 3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

procedure TZoomPanFMXMain.FMXScaling(t: double);
var
  ZoomRect: TRectF;
begin
  ZoomRect := ZoomPanToFloatrect(Animation(t), MovieWidth, MovieHeight);
  if AniBm.Canvas.BeginScene() then
  begin
    Anibm.Canvas.Clear(0);
    AniBm.Canvas.DrawBitmap(MovieBm, ZoomRect, RectF(0, 0, MovieWidth,
      MovieHeight), 1);
    AniBm.Canvas.EndScene;
  end;
end;

procedure TZoomPanFMXMain.FormCreate(Sender: TObject);
var
  i: integer;
begin
  TheSource := TBitmap.Create;
  MovieBm := TBitmap.Create;
  AniBm := TBitmap.Create;
  MakeTestBitmap;
  for i := 0 to 6 do
    Heights.Items.Add(InttoStr(MovieHeights[i]) + ' p');
  Heights.ItemIndex := 2;
  uScaleCommon.InitDefaultResamplingThreads;
  UpdatePositions;
end;

procedure TZoomPanFMXMain.FormDestroy(Sender: TObject);
begin
  TheSource.Free;
  MovieBm.Free;
  AniBm.Free;
end;

function TZoomPanFMXMain.GetScreenScale: single;
begin
  result := Screen.DisplayFromForm(self).Scale;
end;

function TZoomPanFMXMain.GetScreenScaleInv: single;
begin
  result := 1 / Screen.DisplayFromForm(self).Scale;
end;


procedure TZoomPanFMXMain.HeightsChange(Sender: TObject);
begin
  UpdatePositions;
end;

procedure TZoomPanFMXMain.LoadClick(Sender: TObject);
var
  si: single;
begin
  if not OD.Execute() then
    exit;
  TheSource.LoadFromFile(OD.Filename);
  si := ScreenScaleInv;
  Aspect := TheSource.Width / TheSource.Height;
  Image1.Size.Size := PointF(TheSource.Width * si, TheSource.Height * si);
  Image1.Bitmap := TheSource;
  UpdatePositions;
end;

procedure TZoomPanFMXMain.MakeClick(Sender: TObject);
begin
  MakeTestBitmap;
  UpdatePositions;
end;

procedure TZoomPanFMXMain.MakeTestBitmap;
var
  bm: TTestBitmap;
  si: single;
begin
  bm := TTestBitmap.Create;
  try
    bm.Generate(900, tkCircles);
    BitmapVCLToFMX(bm, TheSource);
  finally
    bm.Free;
  end;
  si := ScreenScaleInv;
  Aspect := TheSource.Width / TheSource.Height;
  Image1.Size.Size := PointF(TheSource.Width * si, TheSource.Height * si); //Adjust to bitmap size
  Image1.Bitmap := TheSource;
end;

procedure TZoomPanFMXMain.MovieBoxPaint(Sender: TObject; Canvas: TCanvas);
begin
  Canvas.DrawBitmap(AniBm, RectF(0, 0, MovieWidth, MovieHeight),
    RectF(0, 0, MovieBox.Width, MovieBox.Height), 1, True);
end;

procedure TZoomPanFMXMain.MovieRectResize(Sender: TObject);
begin
  if (csLoading in ComponentState) or (csReading in ComponentState) then
  exit;
  UpdatePositions;
end;

const
  FilterArray: array [0 .. 7] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos, cfMitchell, cfRobidoux, cfRobidouxSharp, cfRobidouxSoft);

type
  TScaleProc = procedure(t: double) of object;

procedure TZoomPanFMXMain.StartClick(Sender: TObject);
var
  StopWatch: TStopWatch;
  t, TimeInv: double;
  Elapsed: int64;
  ScaleProc: TScaleProc;
  Frames: integer;
begin
  if Scaling.ItemIndex = 0 then
    ScaleProc := uScaleScaling
  else
    ScaleProc := FMXScaling;
  StopWatch := TStopWatch.Create;
  Frames := 0;
  TimeInv:=1/15000;
  StopWatch.Start;
  Elapsed := StopWatch.ElapsedMilliseconds;
  while Elapsed < 15000 do
  begin
    t := Elapsed*TimeInv;
    ScaleProc(t);
    inc(Frames);
    MovieBox.Repaint;
    Application.ProcessMessages;
    Elapsed := StopWatch.ElapsedMilliseconds;
  end;
  StopWatch.Stop;
  ScaleProc(1);
  MovieBox.Repaint;
  FPS.Text := round(Frames / 15).ToString + ' fps';
end;

procedure TZoomPanFMXMain.UpdatePositions;
var
  si: single;
  w, h: single;
begin
  if Heights.ItemIndex < 0 then
    exit;
  si := ScreenScaleInv;
  MovieHeight := MovieHeights[Heights.ItemIndex];
  MovieWidth := round(MovieHeight * Aspect);
  h := MovieHeight * si;
  w := MovieWidth * si;
  MovieBox.SetBounds((MovieRect.Width - w) / 2, (MovieRect.Height - h) / 2, w,
    h); // pixel-size of Moviebox = MovieWidth x MovieHeight
  Resample(MovieWidth,MovieHeight,TheSource,MovieBm,cfLanczos,0,false,amIndependent);
  ZoomResample(MovieWidth,MovieHeight,MovieBm,AniBm,ZoomPanToFloatRect(Animation(0),MovieWidth,MovieHeight),cfLanczos,0,amIndependent);
end;

procedure TZoomPanFMXMain.uScaleScaling(t: double);
var
  ZoomRect: TRectF;
begin
  ZoomRect := ZoomPanToFloatrect(Animation(t), MovieWidth, MovieHeight);
  uScaleFMX.ZoomResampleParallelThreads(MovieWidth, MovieHeight, MovieBm, AniBm,
    ZoomRect, FilterArray[Filter.ItemIndex], 0, amIndependent);
end;

initialization

ReportMemoryLeaksOnShutDown := true;

end.
