unit uSharpenMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,

  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Diagnostics,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.Samples.Spin,

  uScaleCommon,
  uScale,
  uTools;

type
  TSharpenMain = class(TForm)
    Panel1: TPanel;
    RadiusSlider: TTrackBar;
    ShowRadius: TLabel;
    AlphaSlider: TTrackBar;
    ShowAlpha: TLabel;
    ThreshSlider: TTrackBar;
    ShowThresh: TLabel;
    Panel2: TPanel;
    Panel3: TPanel;
    ScrollBox1: TScrollBox;
    DisplayOriginal: TImage;
    ScrollBox2: TScrollBox;
    Splitter1: TSplitter;
    GroupBox1: TGroupBox;
    LoadImage: TButton;
    ShowSize: TLabel;
    GroupBox2: TGroupBox;
    ScalePercent: TSpinEdit;
    FODImage: TFileOpenDialog;
    ShowFilter: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    ShowNewSize: TLabel;
    GroupBox3: TGroupBox;
    EnableSharpen: TCheckBox;
    AutoSharpen: TCheckBox;
    GroupBox4: TGroupBox;
    TimeResample: TLabel;
    TimeSharpen: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    GroupBox5: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    FSD: TFileSaveDialog;
    DisplaySharpened: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadImageClick(Sender: TObject);
    procedure RadiusSliderChange(Sender: TObject);
    procedure AlphaSliderChange(Sender: TObject);
    procedure ThreshSliderChange(Sender: TObject);
    procedure ScalePercentChange(Sender: TObject);
    procedure EnableSharpenClick(Sender: TObject);
    procedure DisplaySharpenedClick(Sender: TObject);
    procedure DisplaySharpenedPaint(Sender: TObject);
  private
    { Private-Deklarationen }
    TheOriginal, TheSharpened, TheScaled: TBitmap;
    function GetRadius: single;
    function GetAlpha: single;

    // Important routine using uScale.UnsharpMaskParallel
    procedure DoSharpen;

    procedure DoScale;
    function GetThresh: single;
    function GetNewSize: TPoint;
    function GetFilter: TFilter;
    function GetUnsharpParameters: TUnsharpParameters;
  public
    { Public-Deklarationen }

    // properties to read the input parameters off the form's controls
    property UnsharpParameters: TUnsharpParameters read GetUnsharpParameters;
    property Radius: single read GetRadius;
    property Alpha: single read GetAlpha;
    property Thresh: single read GetThresh;
    property NewSize: TPoint read GetNewSize;
    property Filter: TFilter read GetFilter;
  end;

var
  SharpenMain: TSharpenMain;

implementation

{$R *.dfm}

procedure TSharpenMain.AlphaSliderChange(Sender: TObject);
begin
  if not AlphaSlider.enabled then
    exit;
  ShowAlpha.Caption := 'a=' + FloatToStrF(Alpha, ffFixed, 5, 2);
  DoSharpen;
end;

procedure TSharpenMain.DisplaySharpenedClick(Sender: TObject);
begin
  if FSD.Execute then
    TheSharpened.SaveToFile(FSD.FileName);
end;

procedure TSharpenMain.DoScale;
var
  StopWatch: TStopWatch;
begin
  if (TheOriginal.Width = 0) or (TheOriginal.Height = 0) then
    exit;
  StopWatch := TStopWatch.Create;
  StopWatch.Start;
  if ScalePercent.Value <> 100 then
  begin
    uScale.Resample(NewSize.X, NewSize.Y, TheOriginal, TheScaled, Filter, 0,
      True, amIgnore);
  end
  else
    TheScaled.Assign(TheOriginal);
  StopWatch.Stop;
  TimeResample.Caption := StopWatch.ElapsedMilliseconds.ToString;
end;

procedure TSharpenMain.DoSharpen;
var
  StopWatch: TStopWatch;
begin
  if (TheScaled.Width = 0) or (TheScaled.Height = 0) then
    exit;
  StopWatch := TStopWatch.Create;
  StopWatch.Start;
  if EnableSharpen.Checked then
    // see GetUnsharpParameters
    uScale.UnsharpMaskParallel(TheScaled, TheSharpened, UnsharpParameters)
  else
    TheSharpened.Assign(TheScaled);
  StopWatch.Stop;
  TimeSharpen.Caption := StopWatch.ElapsedMilliseconds.ToString;
  DisplaySharpened.SetBounds(-Scrollbox2.HorzScrollBar.Position,-Scrollbox2.VertScrollBar.Position,TheSharpened.Width,TheSharpened.height);
  DisplaySharpened.Invalidate;
end;

procedure TSharpenMain.EnableSharpenClick(Sender: TObject);
var
  EnableSliders: boolean;
begin
  EnableSliders := EnableSharpen.Checked and (not AutoSharpen.Checked);
  AlphaSlider.enabled := EnableSliders;
  RadiusSlider.enabled := EnableSliders;
  ThreshSlider.enabled := EnableSliders;
  DoSharpen;
end;

procedure TSharpenMain.FormCreate(Sender: TObject);
begin
  uScaleCommon.InitDefaultResamplingThreads;
  TheOriginal := TBitmap.Create;
  TheSharpened := TBitmap.Create;
  TheScaled := TBitmap.Create;
  AlphaSliderChange(nil);
  RadiusSliderChange(nil);
  ThreshSliderChange(nil);
  With DisplaySharpened do
  ControlStyle:=ControlStyle+[csOpaque];
end;

procedure TSharpenMain.FormDestroy(Sender: TObject);
begin
  TheOriginal.Free;
  TheSharpened.Free;
  TheScaled.Free;
end;

function TSharpenMain.GetAlpha: single;
begin
  Result := 1 / 100 * AlphaSlider.Position;
end;

const
  Filters: array [0 .. 3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

function TSharpenMain.GetFilter: TFilter;
begin
  Result := Filters[ShowFilter.ItemIndex];
end;

function TSharpenMain.GetNewSize: TPoint;
var
  scale: double;
begin
  scale := 0.01 * ScalePercent.Value;
  Result.X := round(scale * TheOriginal.Width);
  Result.Y := round(scale * TheOriginal.Height);
end;

function TSharpenMain.GetRadius: single;
begin
  Result := 1 / 100 * RadiusSlider.Position;
end;

function TSharpenMain.GetThresh: single;
begin
  Result := 1 / 100 * ThreshSlider.Position;
end;

function TSharpenMain.GetUnsharpParameters: TUnsharpParameters;
begin
  if AutoSharpen.Checked then
  begin
    Result.AutoValues(TheScaled.Width, TheScaled.Height);
    AlphaSlider.Position := round(100 * Result.Alpha);
    RadiusSlider.Position := round(100 * Result.Radius);
    ThreshSlider.Position := round(100 * Result.Thresh);
    ShowThresh.Caption := 't=' + FloatToStrF(Result.Thresh, ffFixed, 5, 2);
    ShowAlpha.Caption := 'a=' + FloatToStrF(Result.Alpha, ffFixed, 5, 2);
    ShowRadius.Caption := 'r=' + FloatToStrF(Result.Radius, ffFixed, 5, 2);
  end
  else
  begin
    Result.Alpha := Alpha;
    Result.Radius := Radius;
    Result.Thresh := Thresh;
  end;
end;

procedure TSharpenMain.LoadImageClick(Sender: TObject);
var
  wic: TWicImage;
begin
  if not FODImage.Execute then
    exit;
  wic := TWicImage.Create;
  try
    wic.LoadFromFile(FODImage.FileName);
    WicToBmp(wic, TheOriginal);
    DisplayOriginal.Picture.Bitmap := TheOriginal;
    ShowSize.Caption := TheOriginal.Width.ToString + 'x' +
      TheOriginal.Height.ToString;
  finally
    wic.Free;
  end;
  ScalePercentChange(nil);
  DoScale;
  DoSharpen;
end;

procedure TSharpenMain.DisplaySharpenedPaint(Sender: TObject);
begin
  BitBlt(DisplaySharpened.Canvas.Handle,0,0,TheSharpened.Width,TheSharpened.Height,TheSharpened.Canvas.Handle,0,0,SRCCopy);
end;

procedure TSharpenMain.RadiusSliderChange(Sender: TObject);
begin
  if not RadiusSlider.enabled then
    exit;
  ShowRadius.Caption := 'r=' + FloatToStrF(Radius, ffFixed, 5, 2);
  DoSharpen;
end;

procedure TSharpenMain.ScalePercentChange(Sender: TObject);
begin
  ShowNewSize.Caption := NewSize.X.ToString + 'x' + NewSize.Y.ToString;
  DoScale;
  DoSharpen;
end;

procedure TSharpenMain.ThreshSliderChange(Sender: TObject);
begin
  if not ThreshSlider.enabled then
    exit;
  ShowThresh.Caption := 't=' + FloatToStrF(Thresh, ffFixed, 5, 2);
  DoSharpen;
end;

end.
