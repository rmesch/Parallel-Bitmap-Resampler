unit uZoomPanMain;
//Shows how parallel resampling can be used to show
//smooth zooms and pans into an image with a high frame rate.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin, Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.ExtDlgs;

type
  TZoomPanMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    ScrollBox1: TScrollBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Make: TButton;
    Load: TButton;
    MoviePanel: TPanel;
    MovieBox: TPaintBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Heights: TComboBox;
    Time: TSpinEdit;
    Label2: TLabel;
    Start: TButton;
    Image1: TImage;
    Panel5: TPanel;
    FPS: TLabel;
    OPD: TOpenPictureDialog;
    Label3: TLabel;
    Filter: TComboBox;
    Panel6: TPanel;
    RadiusPercent: TSpinEdit;
    Label4: TLabel;
    Radius: TLabel;
    Label5: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure HeightsChange(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure MoviePanelResize(Sender: TObject);
    procedure MakeClick(Sender: TObject);
    procedure MovieBoxPaint(Sender: TObject);
  private
    TheSource, MovieBm: TBitmap;
    Aspect: double;
    MovieWidth, MovieHeight: integer;
    procedure MakeTestBitmap;
    procedure UpdatePositions;
    procedure ShowAnimation;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  ZoomPanMain: TZoomPanMain;

implementation

{$R *.dfm}

uses
//You now need to put uScale and uScaleCommon into the uses clause
uScale, uScaleCommon,
uTools, uTestBitmap, Winapi.MMSystem;

type
  // Defines a normalized zoom-zectangle [xcenter-radius,xcenter+radius]x[ycenter-radius,ycenter+radius]
  // as a sub-rectangle of [0,1]x[0,1]
  // when multiplied by the width/height of an image it defines an aspect-preserving sub-rectangle of
  // the image.
  TZoomPan = record
    xcenter, ycenter, Radius: double;
  end;

function ZoomPanToFloatrect(zp: TZoomPan; w, h: integer): TFloatRect; inline;
begin
  result.Left := (zp.xcenter - zp.Radius) * w;
  result.Top := (zp.ycenter - zp.Radius) * h;
  result.Right := (zp.xcenter + zp.Radius) * w;
  result.Bottom := (zp.ycenter + zp.Radius) * h;
end;

// pan from bottom-left to top-right
// followed by zoom-out to full image
// t runs from 0 to 1
function Animation(t: double): TZoomPan; inline;
begin
  if t < 0.5 then
  begin
    result.Radius := 0.35;
    result.xcenter := 0.35 + 2 * t * 0.3;
    result.ycenter := 0.65 - 2 * t * 0.3;
  end
  else
  begin
    result.Radius := 0.35 + 2 * (t - 0.5) * 0.15;
    result.xcenter := 1 - result.Radius;
    result.ycenter := result.Radius;
  end;
end;

const
  MovieHeights: array [0 .. 6] of integer = (360, 480, 600, 720, 900, 1080, 1440);
  Filters: array [0 .. 3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

procedure TZoomPanMain.FormCreate(Sender: TObject);
var
  i: integer;
begin
  TheSource := TBitmap.Create;
  MovieBm := TBitmap.Create;
  Aspect := 1;
  for i := 0 to 6 do
    Heights.AddItem(InttoStr(MovieHeights[i]) + ' p', nil);
  Heights.ItemIndex := 2;
  MovieBox.ControlStyle := MovieBox.ControlStyle + [csOpaque];
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TPanel then
      with TPanel(Components[i]) do
      begin
        BevelEdges := [];
        BevelOuter := bvNone;
      end;
  MakeTestBitmap;
  UpdatePositions;
end;

procedure TZoomPanMain.MakeClick(Sender: TObject);
begin
  MakeTestBitmap;
  UpdatePositions;
end;

procedure TZoomPanMain.MakeTestBitmap;
var
  bm: TTestBitmap;
begin
  bm := TTestBitmap.Create;
  try
    screen.Cursor := crHourGlass;
    bm.Generate(900, tkCircles);
    TheSource.Assign(bm);
    TheSource.PixelFormat := pf32bit;
    Image1.Picture.Bitmap := TheSource;
    screen.Cursor := crDefault;
  finally
    bm.Free;
  end;
  Aspect := TheSource.Width / TheSource.Height;
end;

procedure TZoomPanMain.MovieBoxPaint(Sender: TObject);
begin
  BitBlt(MovieBox.Canvas.Handle, 0, 0, MovieBox.Width, MovieBox.Height, 0, 0, 0,
    BLACKNESS);
end;

procedure TZoomPanMain.MoviePanelResize(Sender: TObject);
begin
  UpdatePositions;
end;

procedure TZoomPanMain.UpdatePositions;
begin
  var
  h := MovieHeights[Heights.ItemIndex];
  var
  w := round(h * Aspect);
  MovieHeight := h;
  MovieWidth := w;
  MovieBox.SetBounds((MoviePanel.Width - w) div 2, (MoviePanel.Height - h)
    div 2, w, h);
end;

procedure TZoomPanMain.FormDestroy(Sender: TObject);
begin
  TheSource.Free;
  MovieBm.Free;
end;

procedure TZoomPanMain.HeightsChange(Sender: TObject);
begin
  UpdatePositions;
end;

procedure TZoomPanMain.LoadClick(Sender: TObject);
var
  WIC: TWICImage;
begin
  if not OPD.Execute() then
    exit;
  WIC := TWICImage.Create;
  try
    WIC.LoadFromFile(OPD.Filename);
    WICToBmp(WIC,TheSource);
  finally
    WIC.Free;
  end;
  Aspect := TheSource.Width / TheSource.Height;
  Image1.Picture.Bitmap := TheSource;
  UpdatePositions;
end;

procedure TZoomPanMain.ShowAnimation;
var
  ts, elapsed: int64;
  mt: integer; // movie time in ms
  mtInv: double; // 1/mt
  ZoomRect: TFloatRect;
  t: double;
  bm: TBitmap;
  Frames: integer;
  f: TFilter;
  r: single;
begin
  MovieBox.OnPaint:=nil;

  Resample(MovieWidth, MovieHeight, TheSource, MovieBm, cfLanczos, 0, true,
    amIgnore);
  mt := Time.Value * 1000;
  mtInv := 1 / mt;
  f := Filters[Filter.ItemIndex];
  r := DefaultRadius[f] * 0.01 * RadiusPercent.Value;
  bm := TBitmap.Create;
  try
    bm.PixelFormat := pf32bit;
    bm.SetSize(MovieWidth, MovieHeight);
    Frames := 0;
    elapsed := 0;
    ts := TimeGetTime;
    while (elapsed < mt) do
    begin
      t := elapsed * mtInv;
      ZoomRect := ZoomPanToFloatrect(Animation(t), MovieWidth, MovieHeight);
      //resample zoomrect in source with parallel threads using default threadpool
      ZoomResampleParallelThreads(MovieWidth, MovieHeight, MovieBm, bm,
        ZoomRect, f, r, amIgnore);
      BitBlt(MovieBox.Canvas.Handle, 0, 0, MovieWidth, MovieHeight,
        bm.Canvas.Handle, 0, 0, SRCCopy);
      Inc(Frames);
      // This is a tight loop and has been coded like this
      // for demonstration purposes only.
      // One could use a high precision timer instead.
      // sleep(1);
      elapsed := TimeGetTime - ts;
    end;
  finally
    bm.Free;
  end;
  FPS.Caption := InttoStr(round(Frames / Time.Value)) + ' fps';
  Radius.Caption := 'Filter-Radius: ' + FloatToStrF(r, ffFixed, 4, 2);
  MovieBox.OnPaint:=MovieBoxPaint;
end;

procedure TZoomPanMain.StartClick(Sender: TObject);
begin
  ShowAnimation;
end;

Initialization

ReportMemoryLeaksOnShutDown := true;

end.
