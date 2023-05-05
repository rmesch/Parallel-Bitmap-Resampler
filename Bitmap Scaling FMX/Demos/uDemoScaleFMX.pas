unit uDemoScaleFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, uScaleFMX, FMX.Edit,
  FMX.EditBox, FMX.SpinBox, FMX.ListBox, System.ImageList, FMX.ImgList;

type
  TDemoFMXMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel3: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    GroupBox1: TGroupBox;
    Width: TSpinBox;
    Height: TSpinBox;
    Label1: TLabel;
    OriginalSize: TLabel;
    GroupBox2: TGroupBox;
    Filters: TComboBox;
    Threading: TComboBox;
    Timing: TLabel;
    KeepAspect: TCheckBox;
    Scale: TButton;
    GroupBox3: TGroupBox;
    TestSizes: TComboBox;
    Make: TButton;
    TimingSystem: TLabel;
    GroupBox4: TGroupBox;
    Load: TButton;
    Label2: TLabel;
    OD: TOpenDialog;
    Rectangle1: TRectangle;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Rectangle2: TRectangle;
    ScrollBox2: TScrollBox;
    Image2: TImage;
    Rectangle3: TRectangle;
    ScrollBox3: TScrollBox;
    Image3: TImage;
    GroupBox5: TGroupBox;
    CombineModes: TComboBox;
    ImageList1: TImageList;
    ZoomIn: TButton;
    ZoomOut: TButton;
    Button1: TButton;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FiltersChange(Sender: TObject);
    procedure WidthChange(Sender: TObject);
    procedure HeightChange(Sender: TObject);
    procedure ScaleClick(Sender: TObject);
    procedure MakeClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure Panel4Resize(Sender: TObject);
    procedure CombineModesChange(Sender: TObject);
    procedure ZoomInClick(Sender: TObject);
    procedure ZoomOutClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    TheOriginal, TheSource, TheTarget, TheScaled: TBitmap;
    Aspect: double;
    ZoomFact: integer;
    procedure MakeTestBitmapAndRun;
    procedure MakeSourceBitmap;
    procedure DisplaySource;
    procedure UpdateSizes;
    procedure DoScale;
    procedure Display(const bmp: TBitmap; im: TImage);
    procedure DisplayTarget;
    procedure DisplayScaled;
    procedure DisplayZooms;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  DemoFMXMain: TDemoFMXMain;

implementation

{$R *.fmx}

uses uToolsFMX, uTestBitmap, System.Diagnostics, System.Math, WinAPI.D2D1,
  FMX.Canvas.D2D;

function GetBMWidth(i: integer): integer;
begin
  result := 150 + i * 150;
end;

procedure TDemoFMXMain.FiltersChange(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoFMXMain.FormCreate(Sender: TObject);
var
  i: integer;
begin
  TheOriginal := TBitmap.Create;
  TheSource := TBitmap.Create;
  TheTarget := TBitmap.Create;
  TheScaled := TBitmap.Create;
  Aspect := 1;
  ZoomFact := 1;
  uScaleFMX.InitDefaultResamplingThreads;
  for i := 0 to 18 do
    TestSizes.Items.Add(GetBMWidth(i).ToString);
  TestSizes.ItemIndex := 4;
end;

procedure TDemoFMXMain.FormDestroy(Sender: TObject);
begin
  TheTarget.Free;
  TheSource.Free;
  TheOriginal.Free;
  TheScaled.Free;
end;

procedure TDemoFMXMain.FormShow(Sender: TObject);
begin
  MakeTestBitmapAndRun;
end;

procedure TDemoFMXMain.HeightChange(Sender: TObject);
begin
  Width.OnChange := nil;
  if KeepAspect.IsChecked then
    Width.Value := round(Height.Value * Aspect);
  Width.OnChange := WidthChange;
  Width.Repaint;
end;

procedure TDemoFMXMain.LoadClick(Sender: TObject);
begin
  if not OD.Execute then
    exit;
  ZoomFact:=1;
  TheOriginal.LoadFromFile(OD.FileName);
  MakeSourceBitmap;
  DisplaySource;
  UpdateSizes;
  DoScale;
end;

procedure TDemoFMXMain.MakeTestBitmapAndRun;
var
  bm: TTestBitmap;
begin
  ZoomFact:=1;
  bm := TTestBitmap.Create;
  try
    bm.Generate(GetBMWidth(TestSizes.ItemIndex), tkCircles);
    BitmapVCLToFMX(bm, TheOriginal);
  finally
    bm.Free;
  end;
  MakeSourceBitmap;
  UpdateSizes;
  DisplaySource;
  DoScale;
end;

procedure TDemoFMXMain.Panel4Resize(Sender: TObject);
begin
  Panel7.Height := 0.5 * Panel4.Height;
end;

procedure TDemoFMXMain.ScaleClick(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoFMXMain.MakeClick(Sender: TObject);
begin
  MakeTestBitmapAndRun;
end;

procedure TDemoFMXMain.MakeSourceBitmap;
begin
  TheSource.Assign(TheOriginal);
end;

procedure TDemoFMXMain.Display(const bmp: TBitmap; im: TImage);
var
  ScaleInv: single;
begin
  im.Bitmap := nil;
  im.WrapMode := TImageWrapMode.Original;
  ScaleInv := 1 / im.Scene.GetSceneScale;
  // ScaleInv:=1/Screen.Displays[0].Scale;
  im.Bitmap.Assign(bmp);
  im.Bitmap.BitmapScale := 1;
  im.Size.Size := PointF(bmp.Width * ScaleInv, bmp.Height * ScaleInv);
end;

procedure TDemoFMXMain.Button1Click(Sender: TObject);
begin
  ZoomFact:=1;
  DisplayZooms;
end;

procedure TDemoFMXMain.CombineModesChange(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoFMXMain.DisplaySource;
begin
  Display(TheSource, Image1);
end;

procedure TDemoFMXMain.DisplayTarget;
begin
  Display(TheTarget, Image2);
end;

procedure TDemoFMXMain.DisplayScaled;
begin
  Display(TheScaled, Image3);
end;

procedure TDemoFMXMain.UpdateSizes;
var
  w, h: integer;
begin
  w := TheSource.Width;
  h := TheSource.Height;
  Assert(h > 0);
  OriginalSize.Text := 'Original: ' + Inttostr(w) + ' x ' + Inttostr(h);
  Width.max := 20 * w;
  Height.max := 20 * h;
  Aspect := w / h;
  Width.Value := round(93 / 100 * w);
  Height.Value := round(93 / 100 * h);
end;

procedure TDemoFMXMain.WidthChange(Sender: TObject);
begin
  Height.OnChange := nil;
  if KeepAspect.IsChecked then
    Height.Value := round(Width.Value / Aspect);
  Height.OnChange := HeightChange;
  Height.Repaint;
end;

procedure TDemoFMXMain.ZoomInClick(Sender: TObject);
begin
  inc(ZoomFact);
  DisplayZooms;
end;

procedure TDemoFMXMain.ZoomOutClick(Sender: TObject);
begin
  dec(ZoomFact);
  if ZoomFact < 1 then
    ZoomFact := 1;
  DisplayZooms;
end;

procedure TDemoFMXMain.DisplayZooms;
var
  zbm: TBitmap;
begin
  if ZoomFact > 1 then
  begin
    zbm := TBitmap.Create;
    try
      try
      Magnify(TheTarget, zbm, ZoomFact);
      Display(zbm, Image2);
      Magnify(TheScaled, zbm, ZoomFact);
      Display(zbm, Image3);
      except
        ShowMessage('Zoom factor too large');
        dec(zoomfact);
      end;
    finally
      zbm.Free;
    end;
  end
  else
  begin
    DisplayTarget;
    DisplayScaled;
  end;
end;

const
  FilterArray: array [0 .. 3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

procedure TDemoFMXMain.DoScale;
var
  StopWatch: TStopWatch;
  nw, nh: integer;
  Filter: TFilter;
  r, rDst: TRectF;
  acm: TAlphaCombineMode;
begin
  StopWatch := TStopWatch.Create;
  acm := TAlphaCombineMode(CombineModes.ItemIndex);
  nw := trunc(Width.Value);
  nh := trunc(Height.Value);
  r := RectF(0, 0, TheSource.Width, TheSource.Height);
  Filter := FilterArray[Filters.ItemIndex];
  StopWatch.Start;
  case Threading.ItemIndex of
    0:
      uScaleFMX.ZoomResample(nw, nh, TheSource, TheTarget, r, Filter, 0, acm);
    1:
      uScaleFMX.ZoomResampleParallelThreads(nw, nh, TheSource, TheTarget, r,
        Filter, 0, acm);
    2:
      uScaleFMX.ZoomResampleParallelTasks(nw, nh, TheSource, TheTarget, r,
        Filter, 0, acm);
  end;
  StopWatch.Stop;
  Timing.Text := (StopWatch.ElapsedTicks div 1000).ToString + ' Mega-Ticks';
  rDst := RectF(0, 0, nw, nh);
  StopWatch.Reset;
  StopWatch.Start;
  TheScaled.SetSize(nw, nh);
  if TheScaled.Canvas.BeginScene() then
  begin
    TheScaled.Canvas.DrawBitmap(TheSource, r, rDst, 1, False);
    TheScaled.Canvas.EndScene;
    StopWatch.Stop;
    TimingSystem.Text := (StopWatch.ElapsedTicks div 1000).ToString +
      ' Mega-Ticks';
  end;
  DisplayZooms;
end;

initialization

ReportMemoryLeaksOnShutDown := true;

end.
