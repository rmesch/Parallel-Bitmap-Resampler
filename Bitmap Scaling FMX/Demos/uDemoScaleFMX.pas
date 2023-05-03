unit uDemoScaleFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, uScaleFMX, FMX.Edit,
  FMX.EditBox, FMX.SpinBox, FMX.ListBox;

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
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    ScrollBox3: TScrollBox;
    Image3: TImage;
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
    Image1: TImage;
    Rectangle2: TRectangle;
    Image2: TImage;
    Rectangle3: TRectangle;
    Image4: TImage;
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FiltersChange(Sender: TObject);
    procedure WidthChange(Sender: TObject);
    procedure HeightChange(Sender: TObject);
    procedure ScaleClick(Sender: TObject);
    procedure MakeClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
  private
    TheOriginal, TheSource, TheTarget, TheScaled: TBitmap;
    Aspect: double;
    procedure MakeTestBitmapAndRun;
    procedure MakeSourceBitmap;
    procedure DisplaySource;
    procedure UpdateSizes;
    procedure DoScale;
    procedure Display(const bmp: TBitmap; im: TImage);
    procedure DisplayTarget;
    procedure DisplayScaled;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  DemoFMXMain: TDemoFMXMain;

implementation

{$R *.fmx}

uses uToolsFMX, uTestBitmap, System.Diagnostics;

function GetBMWidth(i: Integer): Integer;
begin
  result := 150 + i * 150;
end;

procedure TDemoFMXMain.FiltersChange(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoFMXMain.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  TheOriginal := TBitmap.Create;
  TheSource := TBitmap.Create;
  TheTarget := TBitmap.Create;
  TheScaled := TBitmap.Create;
  Aspect := 1;
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

procedure TDemoFMXMain.FormResize(Sender: TObject);
begin
  Panel1.Width := 0.5 * (clientWidth - Splitter1.Width);
  Panel7.Height := 0.5 * Panel4.Height;
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
begin
  im.Width := bmp.Width;
  im.Height := bmp.Height;
  im.Bitmap.Assign(bmp);
  im.Bitmap.BitmapScale := 1;
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
  w, h: Integer;
begin
  w := TheSource.Width;
  h := TheSource.Height;
  Assert(h > 0);
  OriginalSize.Text := 'Original: ' + Inttostr(w) + ' x ' + Inttostr(h);
  Width.Max := 20 * w;
  Height.Max := 20 * h;
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

const
  FilterArray: array [0 .. 3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

procedure TDemoFMXMain.DoScale;
var
  StopWatch: TStopWatch;
  nw, nh: Integer;
  Filter: TFilter;
  r, rDst: TRectF;
begin
  StopWatch := TStopWatch.Create;
  nw := trunc(Width.Value);
  nh := trunc(Height.Value);
  r := RectF(0, 0, TheSource.Width, TheSource.Height);
  Filter := FilterArray[Filters.ItemIndex];
  StopWatch.Start;
  case Threading.ItemIndex of
    0:
      uScaleFMX.ZoomResample(nw, nh, TheSource, TheTarget, r, Filter, 0,
        amIndependent);
    1:
      uScaleFMX.ZoomResampleParallelThreads(nw, nh, TheSource, TheTarget, r,
        Filter, 0, amIndependent);
    2:
      uScaleFMX.ZoomResampleParallelTasks(nw, nh, TheSource, TheTarget, r,
        Filter, 0, amIndependent);
  end;
  StopWatch.Stop;
  Timing.Text := StopWatch.ElapsedMilliseconds.ToString + ' ms';
  DisplayTarget;
  rDst := RectF(0, 0, nw, nh);
  TheScaled.SetSize(nw, nh);
  StopWatch.Reset;
  StopWatch.Start;
  if TheScaled.Canvas.BeginScene() then
  begin
    TheScaled.Canvas.DrawBitmap(TheSource, r, rDst, 1, False);
    TheScaled.Canvas.EndScene;
    StopWatch.Stop;
    DisplayScaled;
    TimingSystem.Text := StopWatch.ElapsedMilliseconds.ToString + ' ms';
  end;
end;

initialization

ReportMemoryLeaksOnShutDown := true;

end.
