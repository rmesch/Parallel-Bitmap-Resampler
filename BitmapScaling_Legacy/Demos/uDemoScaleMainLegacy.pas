unit uDemoScaleMainLegacy;
// Shows how to resample a source-bitmap to a target-bitmap using the
// procedures in uScaleLegacy with various settings.
// Look at TDemoMainForm.DoScale to see how the procedures are used.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls, StdCtrls,
  ExtDlgs, ImgList, jpeg, uScaleLegacy, uScaleCommonLegacy, Spin;

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
    ScrollBox3: TScrollBox;
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
    SPD: TSavePictureDialog;
    ZoomIn: TButton;
    ZoomOut: TButton;
    NoZoom: TButton;
    SourceBox: TPaintBox;
    TargetBox: TPaintBox;
    HalftoneBox: TPaintBox;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure MakeTestBitmapClick(Sender: TObject);
    //procedure ShowAlphaClick(Sender: TObject);
    procedure AlphaChannelClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure WidthChange(Sender: TObject);
    procedure HeightChange(Sender: TObject);
    procedure ResizeClick(Sender: TObject);
    procedure ThreadingChange(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    //procedure ShowAlphaTargetClick(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image2MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    //procedure ShowAlphaWICClick(Sender: TObject);
    procedure Image3MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure Image3MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure ScrollBox1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure Panel7Resize(Sender: TObject);
    procedure ZoomInClick(Sender: TObject);
    procedure ZoomOutClick(Sender: TObject);
    procedure NoZoomClick(Sender: TObject);
    procedure SourceBoxPaint(Sender: TObject);
    procedure HalftoneBoxPaint(Sender: TObject);
  private
    //Original as loaded from file or created as test bitmap
    TheOriginal,

    //Original with modified alpha-channel. Source-bmp for rescaling.
    TheSource,

    //Target-bmps for rescaling
    TheTarget, TheHalfTone,

    //Bitmaps for display in the paintboxes.
    //Depending on the settings they can be transparent or not,
    //or have the alpha-channel pre-multiplied.
    PicSource, PicTarget, PicHalfTone: TBitmap;
    Aspect: double;
    ShowAlpha, Transparency: Boolean;
    ZoomFact: Integer;
    Freq, Counter: int64;
    TimingFact: extended;
    //returns present system time in microseconds
    function TimeNow: int64; inline;
    procedure MakeTestBitmapAndRun;
    
    procedure MakeSourceAlpha;
    procedure UpdateSizes;

    // Most important routine to see how to use uScale
    procedure DoScale;

    procedure DisplaySource;
    procedure DisplayTarget;
    procedure DisplayHalftone;
    procedure Display(const bm: TBitmap; const bmPic: TBitmap; const PaintBox: TPaintBox);
    procedure DisplayAlpha(const bm: TBitmap; const bmPic: TBitmap; const PaintBox: TPaintBox);
    procedure DisplayBGR(const bm: TBitmap; const bmPic: TBitmap; const PaintBox: TPaintBox);
    procedure DisplayZooms;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;


var
  DemoMain: TDemoMain;

implementation

{$R *.dfm}

uses uToolsLegacy, uTestBitmapLegacy, Math;

function GetBMWidth(i: Integer): Integer;
begin
  result := 150 + i * 150;
end;

procedure TDemoMain.ThreadingChange(Sender: TObject);
begin
  DoScale;
end;

function TDemoMain.TimeNow: int64;
begin
  QueryPerformanceCounter(Counter);
  result:=round(TimingFact*Counter);
end;

procedure TDemoMain.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  Aspect := 1;
  ZoomFact := 1;
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
  TheHalfTone := TBitmap.Create;
  PicSource:=TBitmap.Create;
  PicTarget:=TBitmap.Create;
  PicHalfTone:=TBitmap.Create;
  InitDefaultResamplingThreads;
  if
  QueryPerformanceFrequency(Freq) then
  TimingFact:=1000*1000/Freq
  else
  begin
    ShowMessage('Timing could not be initialized');
    TimingFact:=0;
  end;
end;

procedure TDemoMain.FormDestroy(Sender: TObject);
begin
  TheSource.Free;
  TheOriginal.Free;
  TheTarget.Free;
  TheHalfTone.Free;
  PicSource.Free;
  PicTarget.Free;
  PicHalfTone.Free;
  uScaleCommonLegacy.FinalizeDefaultResamplingThreads;
end;

procedure TDemoMain.FormShow(Sender: TObject);
begin
  MakeTestBitmapAndRun;
end;

procedure TDemoMain.HalftoneBoxPaint(Sender: TObject);
begin
  HalfToneBox.Canvas.Draw(0,0,PicHalftone);
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
  pb: TPaintBox;
begin
   pb := TPaintBox(Sender);
  if Button = mbRight then
    DisplayAlpha(TheSource, PicSource,pb)
  else
    DisplayBGR(TheSource, PicSource,pb);
end;

procedure TDemoMain.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
begin
  DisplaySource;
end;

procedure TDemoMain.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
var
  pb: TPaintBox;
begin
  if ZoomFact > 1 then
    exit;
  pb := TPaintBox(Sender);
  if Button = mbRight then
    DisplayAlpha(TheTarget, PicTarget,pb)
  else
    DisplayBGR(TheTarget, PicTarget,pb);
end;

procedure TDemoMain.Image2MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
begin
  if ZoomFact > 1 then
    exit;
  DisplayTarget;
end;

procedure TDemoMain.Image3MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
var
  pb: TPaintBox;
begin
  if ZoomFact > 1 then
    exit;
  pb := TPaintBox(Sender);
  if Button = mbRight then
    DisplayAlpha(TheHalftone, PicHalftone,pb)
  else
    DisplayBGR(TheHalftone, PicHalfTone,pb);
end;

procedure TDemoMain.Image3MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, Y: Integer);
begin
  if ZoomFact > 1 then
    exit;
  DisplayHalfTone;
end;

procedure TDemoMain.LoadClick(Sender: TObject);
var
  pic: TPicture;
begin
  if not OPD.Execute() then
    exit;
  ZoomFact := 1;
  pic := TPicture.Create;
  try
    pic.LoadFromFile(OPD.Filename);
    
    TheOriginal.Assign(pic.Graphic);
  finally
    pic.Free;
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
  ZoomFact := 1;
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
  Width.Value := round(70 / 100 * w);
  Height.Value := round(70 / 100 * h);
end;

procedure TDemoMain.WidthChange(Sender: TObject);
begin
  Height.OnChange := nil;
  if KeepAspect.Checked then
    Height.Value := round(Width.Value / Aspect);
  Height.OnChange := HeightChange;
end;

procedure TDemoMain.ZoomInClick(Sender: TObject);
begin
  inc(ZoomFact);
  DisplayZooms;
end;

procedure TDemoMain.ZoomOutClick(Sender: TObject);
begin
  dec(ZoomFact);
  DisplayZooms;
end;

procedure TDemoMain.AlphaChannelClick(Sender: TObject);
begin
  MakeSourceAlpha;
  DisplaySource;
  DoScale;
end;

procedure TDemoMain.DisplayAlpha(const bm: TBitmap; const bmPic: TBitmap; const PaintBox: TPaintBox);
var
  bmAlpha: TBitmap;
begin
  bmAlpha := TBitmap.Create;
  try
    CopyAlphaChannel(bm, bmAlpha);
    bmPic.Assign(bmAlpha);
  finally
    bmAlpha.Free;
  end;
  PaintBox.Invalidate;
end;

procedure TDemoMain.DisplayBGR(const bm: TBitmap; const bmPic: TBitmap; const PaintBox: TPaintBox);
begin
  bmPic.Assign(bm);
  bmPic.Transparent:=false;
  bmPic.PixelFormat:=pf24bit;
  Paintbox.Width:=bmPic.Width;
  Paintbox.Height:=bmPic.Height;
  PaintBox.Invalidate;
end;

procedure TDemoMain.ApplyClick(Sender: TObject);
begin
  DoScale;
end;

procedure TDemoMain.Display(const bm: TBitmap; const bmPic: TBitmap; const PaintBox: TPaintBox);
begin
  bmPic.Assign(bm);
  if ShowAlpha then
  begin
    ApplyAlpha(bmPic);
  end
  else
  if not Transparency then

    SetOpaque(bmPic);
  Paintbox.Width:=bmPic.Width;
  Paintbox.Height:=bmPic.Height;
end;

procedure TDemoMain.DisplaySource;
begin
  Display(TheSource, PicSource, SourceBox);
  PicSource.Transparent:=Transparency;
  SourceBox.Invalidate;
end;

procedure TDemoMain.DisplayTarget;
begin
  Display(TheTarget, PicTarget, TargetBox);
  TargetBox.Invalidate;
end;

procedure TDemoMain.DisplayHalftone;
begin
  //Stretch-Halftone erases the alpha-channel,
  //so we use draw for display
  PicHalfTone.Assign(TheHalftone);
  Halftonebox.Width:=PicHalftone.Width;
  Halftonebox.Height:=PicHalftone.Height;
  HalfToneBox.Repaint;
end;

procedure TDemoMain.DisplayZooms;
var
  zbm: TBitmap;
begin
  ZoomFact := max(ZoomFact, 1);
  if ZoomFact = 1 then
  begin
    DisplayTarget;
    DisplayHalftone;
    exit;
  end;
  zbm := TBitmap.Create;
  try
    try
      Magnify(TheTarget, zbm, ZoomFact);
      Display(zbm, picTarget, TargetBox);
      picTarget.Transparent:=TheTarget.Transparent;
      TargetBox.Invalidate;
      Magnify(TheHalftone, zbm, ZoomFact);
      Display(zbm, picHalftone, HalftoneBox);
      picHalftone.Transparent:=TheHalftone.Transparent;
      HalftoneBox.Invalidate;
    except
      ShowMessage('Zoom factor too large!');
      dec(ZoomFact);
    end;
  finally
    zbm.Free;
  end;
end;

const
  FilterArray: array[0..3] of TFilter = (cfBox, cfBilinear, cfBicubic,
    cfLanczos);

  // Scale source to target iteratively in Steps.Value steps

procedure TDemoMain.DoScale;
var
  Filter: TFilter;
  Timing, Start: Int64;
  bm, help: TBitmap;
  nw, nh, deltaw, i: Integer;
  r: single;
  acm: TAlphaCombineMode;
begin
  screen.Cursor := crHourGlass;
  Filter := FilterArray[Filters.ItemIndex];
  r := 0.01 * RadiusPercent.Value * DefaultRadius[Filter]; // Filter-Radius
  acm := TAlphaCombineMode(CombineModes.ItemIndex);
  TheHalftone.SetSize(0, 0);
  TheTarget.SetSize(0, 0); // erase previous alpha
  deltaw := (TheSource.Width - Width.Value) div Steps.Value;
  bm := TBitmap.Create;
  try
    bm.Assign(TheSource);
    nw := TheSource.Width;
    // rescale optionally in more than one step
    timing := 0;
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
        Start := TimeNow;
        case Threading.ItemIndex of
          0:
            ZoomResample(nw, nh, bm, help, FloatRect(0, 0, bm.Width, bm.Height),
              Filter, r, acm);
          1: // the thread pool is not specified, will use default.
            ZoomResampleParallelThreads(nw, nh, bm, help,
              FloatRect(0, 0, bm.Width, bm.Height), Filter, r, acm);
        end;
        inc(timing, TimeNow - Start);
        bm.Assign(help);
      finally
        help.Free;
      end;
      if i = Steps.Value then
        TheTarget.Assign(bm);
    end; // for i
    if acm = amTransparentColor then
    TheTarget.Transparent:=true;
  finally
    bm.Free;
  end;
  if CombineModes.ItemIndex = 3 then
    TheTarget.Transparent := true;
  Time.Caption := FloatToStrF(1/1000*Timing,ffFixed,5,2) + ' ms';
  Radius.Caption := 'Filter-Radius: ' + FloatToStrF(r, ffFixed, 4, 2);

  Timing := 0;
  bm := TBitmap.Create;
  try
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
        Start := TimeNow;

        ScaleStretchHalfTone(nw, nh, bm, help,
          TAlphaCombineMode(CombineModes.ItemIndex));
        inc(timing, TimeNow - Start);
        bm.Assign(help);
      finally
        help.Free;
      end;
      if i = Steps.Value then
        TheHalftone.Assign(bm);
    end;
    if acm = amTransparentColor then
    TheHalfTone.Transparent:=true;
  finally
    bm.Free;
  end;
  DisplayZooms;
  TimeWIC.Caption := FloatToStrF(1/1000*Timing,ffFixed,5,2) + ' ms';
  screen.Cursor := crDefault;
end;

procedure TDemoMain.MakeSourceAlpha;
begin
  TheSource.Assign(TheOriginal);
  TheSource.PixelFormat := pf32bit;
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

procedure TDemoMain.NoZoomClick(Sender: TObject);
begin
  ZoomFact := 1;
  DisplayZooms;
end;

procedure TDemoMain.Panel7Resize(Sender: TObject);
begin
  Panel8.Height := Panel7.Height div 2;
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

procedure TDemoMain.SourceBoxPaint(Sender: TObject);
var pb: TPaintBox;
    pic: TBitmap;
begin
  pb:=TPaintBox(sender);
  if pb=SourceBox then
  pic:=picSource
  else
  pic:=picTarget;
  if transparency or (pic.PixelFormat<>pf32bit) or (not ShowAlpha) then
  pb.Canvas.Draw(0,0,pic)
  else
  DrawAlphaBlended(pic,pb.Canvas,0,0);
end;

initialization

  ReportMemoryLeaksOnShutDown := true;

end.

