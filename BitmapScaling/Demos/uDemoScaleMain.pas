unit uDemoScaleMain;
//Shows how to resample a source-bitmap to a target-bitmap using the
//procedures in uScale with various settings.
//Look at TDemoMainForm.DoScale to see how the procedures are used.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin, Vcl.ExtDlgs, uScale;

type
  TDemoMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    ScrollBox1: TScrollBox;
    GroupBox1: TGroupBox;
    BitmapSize: TComboBox;
    Label1: TLabel;
    MakeTestBitmap: TButton;
    Image1: TImage;
    OriginalSize: TLabel;
    AlphaChannel: TRadioGroup;
    GroupBox2: TGroupBox;
    Width: TSpinEdit;
    Height: TSpinEdit;
    Label2: TLabel;
    KeepAspect: TCheckBox;
    Resize: TButton;
    CombineModes: TRadioGroup;
    GroupBox3: TGroupBox;
    Filters: TComboBox;
    Threading: TComboBox;
    GroupBox4: TGroupBox;
    OPD: TOpenPictureDialog;
    Load: TButton;
    Steps: TSpinEdit;
    Label3: TLabel;
    Panel7: TPanel;
    Panel8: TPanel;
    Splitter2: TSplitter;
    Panel9: TPanel;
    ScrollBox2: TScrollBox;
    Image2: TImage;
    ScrollBox3: TScrollBox;
    Image3: TImage;
    Panel6: TPanel;
    Time: TLabel;
    Panel10: TPanel;
    TimeWIC: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label4: TLabel;
    Label8: TLabel;
    RadiusPercent: TSpinEdit;
    Radius: TLabel;
    Apply: TButton;
    procedure FormCreate(Sender: TObject);
    procedure MakeTestBitmapClick(Sender: TObject);
    procedure ShowAlphaClick(Sender: TObject);
    procedure AlphaChannelClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure WidthChange(Sender: TObject);
    procedure HeightChange(Sender: TObject);
    procedure ResizeClick(Sender: TObject);
    procedure ThreadingChange(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ShowAlphaTargetClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image2MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure ShowAlphaWICClick(Sender: TObject);
    procedure Image3MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image3MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure ScrollBox1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    TheSource, TheOriginal, TheTarget, TheWIC: TBitmap;
    Aspect: double;
    ShowAlpha, Transparency: Boolean;
    procedure MakeTestBitmapAndRun;
    procedure DisplaySource;
    procedure MakeSourceAlpha;
    procedure UpdateSizes;

    // Most important routine to see how to use uScale
    procedure DoScale;

    procedure DisplayTarget;
    procedure DisplayWIC;
    procedure Display(const bm: TBitmap; const im: TImage);
    procedure DisplayAlpha(const bm: TBitmap; im: TImage);
    procedure DisplayBGR(const bm: TBitmap; im: TImage);
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  DemoMain: TDemoMain;

implementation

{$R *.dfm}

uses uTools, System.Diagnostics;

function GetBMWidth(i: Integer): Integer;
begin
  result := 150 + i * 150;
end;

procedure TDemoMain.ThreadingChange(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoMain.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  Aspect := 1;

  // Make all panels flat
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TPanel then
      with TPanel(Components[i]) do
      begin
        Caption := '';
        BevelEdges := [];
        BevelOuter := bvNone;
      end;

  BitmapSize.DropDownCount := 20;
  for i := 0 to 19 do
    BitmapSize.AddItem(Inttostr(GetBMWidth(i)), nil);
  BitmapSize.ItemIndex := 4;

  TheSource := TBitmap.Create;
  TheOriginal := TBitmap.Create;
  TheTarget := TBitmap.Create;
  TheWIC := TBitmap.Create;
  uScale.InitDefaultResamplingThreads;
end;

procedure TDemoMain.FormDestroy(Sender: TObject);
begin
  TheSource.Free;
  TheOriginal.Free;
  TheTarget.Free;
  TheWIC.Free;
  uScale.FinalizeDefaultResamplingThreads;
end;

procedure TDemoMain.FormResize(Sender: TObject);
begin
  Panel1.Width := clientwidth div 2;
  Panel8.Height := Panel7.Height div 2;
end;

procedure TDemoMain.FormShow(Sender: TObject);
begin
  MakeTestBitmapAndRun;
end;

procedure TDemoMain.HeightChange(Sender: TObject);
begin
  Width.OnChange := nil;
  if KeepAspect.Checked then
    Width.Value := round(Height.Value * Aspect);
  Width.OnChange := WidthChange;
end;

procedure TDemoMain.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
var
  im: TImage;
begin
  im := TImage(Sender);
  if Button = mbRight then
    DisplayAlpha(TheSource, im)
  else
    DisplayBGR(TheSource, im);
end;

procedure TDemoMain.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
begin
  DisplaySource;
end;

procedure TDemoMain.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
var
  im: TImage;
begin
  im := TImage(Sender);
  if Button = mbRight then
    DisplayAlpha(TheTarget, im)
  else
    DisplayBGR(TheTarget, im);
end;

procedure TDemoMain.Image2MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
begin
  DisplayTarget;
end;

procedure TDemoMain.Image3MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
var
  im: TImage;
begin
  im := TImage(Sender);
  if Button = mbRight then
    DisplayAlpha(TheWIC, im)
  else
    DisplayBGR(TheWIC, im);
end;

procedure TDemoMain.Image3MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
begin
  DisplayWIC;
end;

procedure TDemoMain.LoadClick(Sender: TObject);
var
  WIC: TWICImage;
begin
  if not OPD.Execute() then
    exit;
  WIC := TWICImage.Create;
  try
    WIC.LoadFromFile(OPD.FileName);
    WICToBmp(WIC, TheOriginal);
  finally
    WIC.Free;
  end;
  MakeSourceAlpha;
  DisplaySource;
  UpdateSizes;
  DoScale;
end;

procedure TDemoMain.MakeTestBitmapAndRun;
var
  bm: TTestBitmap;
begin
  bm := TTestBitmap.Create;
  try
    screen.Cursor := crHourGlass;
    bm.Generate(GetBMWidth(BitmapSize.ItemIndex), tkCircles);
    TheOriginal.Assign(bm);
    TheOriginal.PixelFormat := pf32bit;
    MakeSourceAlpha;
    DisplaySource;
    screen.Cursor := crDefault;
  finally
    bm.Free;
  end;
  UpdateSizes;
  DoScale;
end;

procedure TDemoMain.UpdateSizes;
var
  w, h: Integer;
begin
  w := TheSource.Width;
  h := TheSource.Height;
  OriginalSize.Caption := 'Original: ' + Inttostr(w) + ' x ' + Inttostr(h);
  Width.MaxValue := 20 * w;
  Height.MaxValue := 20 * h;
  Aspect := w / h;
  Width.Value := round(93 / 100 * w);
  Height.Value := round(93 / 100 * h);
end;

procedure TDemoMain.WidthChange(Sender: TObject);
begin
  Height.OnChange := nil;
  if KeepAspect.Checked then
    Height.Value := round(Width.Value / Aspect);
  Height.OnChange := HeightChange;
end;

procedure TDemoMain.AlphaChannelClick(Sender: TObject);
begin
  MakeSourceAlpha;
  DisplaySource;
  DoScale;
end;

procedure TDemoMain.DisplayAlpha(const bm: TBitmap; im: TImage);
var
  bmAlpha: TBitmap;
begin
  bmAlpha := TBitmap.Create;
  try
    CopyAlphaChannel(bm, bmAlpha);
    im.Picture := nil;
    im.Invalidate;
    im.Picture.Bitmap := bmAlpha;
  finally
    bmAlpha.Free;
  end;
end;

procedure TDemoMain.DisplayBGR(const bm: TBitmap; im: TImage);
begin
  im.Picture := nil;
  im.Invalidate;
  im.Picture.Bitmap := bm;
  im.Picture.Bitmap.AlphaFormat := afIgnored;
  im.Invalidate;
end;

procedure TDemoMain.ApplyClick(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoMain.Display(const bm: TBitmap; const im: TImage);
begin
  im.Picture := nil;
  im.Transparent := false;
  im.Invalidate;
  im.Picture.Bitmap := bm;
  if Transparency then
    im.Transparent := true
  else if ShowAlpha then
    im.Picture.Bitmap.AlphaFormat := afDefined
  else
    im.Picture.Bitmap.AlphaFormat := afIgnored;

  im.Invalidate;
end;

procedure TDemoMain.DisplaySource;
begin
  Display(TheSource, Image1);
end;

procedure TDemoMain.DisplayTarget;
begin
  Display(TheTarget, Image2);
end;

procedure TDemoMain.DisplayWIC;
begin
  Display(TheWIC, Image3);
end;

const
  FilterArray: Array [0 .. 3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

  // Scale source to target iteratively in Steps.Value steps
procedure TDemoMain.DoScale;
var
  Filter: TFilter;
  StopWatch: TStopWatch;
  Timing: Int64;
  bm, help: TBitmap;
  nw, nh, deltaw, i: Integer;
  r: single;
  acm: TAlphaCombineMode;
begin
  screen.Cursor := crHourGlass;
  Filter := FilterArray[Filters.ItemIndex];
  r := 0.01 * RadiusPercent.Value * DefaultRadius[Filter]; // Filter-Radius
  acm := TAlphaCombineMode(CombineModes.ItemIndex);
  TheWIC.SetSize(0, 0);
  TheTarget.SetSize(0, 0); // erase previous alpha
  deltaw := (TheSource.Width - Width.Value) div Steps.Value;
  StopWatch := TStopWatch.Create;
  bm := TBitmap.Create;
  try
    bm.Assign(TheSource);
    nw := TheSource.Width;
    //rescale optionally in more than one step
    for i := 1 to Steps.Value do
    begin
      if i = Steps.Value then
      begin
        nw := Width.Value;
        nh := Height.Value;
      end
      else
      begin
        nw := nw - deltaw;
        nh := round(nw / Aspect);
      end;

      help := TBitmap.Create;
      try
        StopWatch.Start;
        case Threading.ItemIndex of
          0:
            ZoomResample(nw, nh, bm, help, FloatRect(0, 0, bm.Width, bm.Height),
              Filter, r, acm);
          1: //the thread pool is not specified, will use default.
            ZoomResampleParallelThreads(nw, nh, bm, help,
              FloatRect(0, 0, bm.Width, bm.Height), Filter, r, acm);
          2:
            ZoomResampleParallelTasks(nw, nh, bm, help,
              FloatRect(0, 0, bm.Width, bm.Height), Filter, r, acm);
        end;
        StopWatch.Stop;
        bm.Assign(help);
      finally
        help.Free;
      end;
      if i = Steps.Value then
        TheTarget.Assign(bm);
    end; // for i
  finally
    bm.Free;
  end;
  if CombineModes.ItemIndex = 3 then
    TheTarget.Transparent := true;
  DisplayTarget;
  Timing := StopWatch.ElapsedMilliseconds;
  Time.Caption := Inttostr(Timing) + ' ms';
  Radius.Caption := 'Filter-Radius: ' + FloatToStrF(r, ffFixed, 4, 2);

  StopWatch.Reset;
  bm := TBitmap.Create;
  try
    // keep TheSource from being altered by the
    // WICImage-rescaling
    bm.Assign(TheSource);
    nw := TheSource.Width;
    for i := 1 to Steps.Value do
    begin
      if i = Steps.Value then
      begin
        nw := Width.Value;
        nh := Height.Value;
      end
      else
      begin
        nw := nw - deltaw;
        nh := round(nw / Aspect);
      end;

      help := TBitmap.Create;
      try
        StopWatch.Start;
        ScaleWICImagingBicubic(nw, nh, bm, help,
          TAlphaCombineMode(CombineModes.ItemIndex));
        StopWatch.Stop;
        bm.Assign(help);
      finally
        help.Free;
      end;
      if i = Steps.Value then
        TheWIC.Assign(bm);
    end;
  finally
    bm.Free;
  end;
  DisplayWIC;
  Timing := StopWatch.ElapsedMilliseconds;
  TimeWIC.Caption := Inttostr(Timing) + ' ms';
  screen.Cursor := crDefault;
end;

procedure TDemoMain.MakeSourceAlpha;
begin
  TheSource.Assign(TheOriginal);
  Transparency := false;
  if AlphaChannel.ItemIndex = 0 then
  begin
    MakeAlphaChannel(TheSource);
    ShowAlpha := true;
  end
  else if AlphaChannel.ItemIndex = 1 then
    ShowAlpha := false
  else if AlphaChannel.ItemIndex = 3 then
  begin
    // erase alpha-channel, otherwise TImage won't use the transparent color
    ClearAlphaChannel(TheSource);
    ShowAlpha := false;
    Transparency := true;
  end
  else
    ShowAlpha := true;
end;

procedure TDemoMain.MakeTestBitmapClick(Sender: TObject);
begin
  MakeTestBitmapAndRun;
end;

procedure TDemoMain.ResizeClick(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoMain.ScrollBox1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  with TScrollBox(Sender) do
    VertScrollbar.Position := VertScrollbar.Position - WheelDelta;
  Handled := true;
end;

procedure TDemoMain.ShowAlphaClick(Sender: TObject);
begin
  DisplaySource;
end;

procedure TDemoMain.ShowAlphaTargetClick(Sender: TObject);
begin
  DisplayTarget;
end;

procedure TDemoMain.ShowAlphaWICClick(Sender: TObject);
begin
  DisplayWIC;
end;

Initialization

ReportMemoryLeaksOnShutDown := true;

end.
