unit uThreadsInThreadsMain;

//Thumbnail viewer which makes the thumb-bitmaps in 2 threads,
//which also use threaded resampling.
//Each thread uses its own custom TResamplingThreadpool.
//Click on a thumb shows the picture in a larger window,
//with resizing also done by parallel threads using the
//default thread pool of uScale.
//Should be a crashtest for thread-safety.
//Important routines: TMakeThumbsThread.DoMakeThumbs,
//TThreadsInThreadsMain.MakeNewThumbs, TThreadsInThreadsMain.ThumbClick.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.FileCtrl, Vcl.ExtCtrls,
  System.Generics.Collections, uScale, System.SyncObjs;

type

  TThumbControl = class;

  TThumbData = record
    Filename: string;
    Bitmap: TBitmap;
    ThumbControl: TThumbControl;
    OrgSize: TPoint;
  end;

  TThumblist = record
    ThumbCount: integer;
    ThumbSize, DetailsSize: integer;
    ThumbParent: TScrollbox;
    DataList: Tarray<TThumbData>;
    OnThumbClick: TNotifyEvent;
    procedure MakeLists(const aDirectory, aFileMask: string;
      const aThumbClick: TNotifyEvent);
    procedure ClearThumbs;
    procedure PaintThumb(Index: integer; aCanvas: TCanvas);
    procedure RedisplayThumbs;
  end;

  PThumblist = ^TThumblist;

  TThumbControl = class(TControl)
  private
    fThumblist: PThumblist;
    fThumbIndex: integer;
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
  end;

  TMakeThumbsThread = class(TThread)
  private
    procedure DoMakeThumbs;
  protected
    procedure Execute; override;
  public
    DoAbort, Working: boolean;
    MessageMemo: TMemo;
    fThumblist: PThumblist;
    fThreadpool: PResamplingThreadpool;
    Transparency: boolean;
    LowerHalf: boolean;
    Ready, Wakeup: TEvent;
    ElapsedLoad, ElapsedResample: int64;
    OnDone: TNotifyEvent;
    constructor Create;
    destructor Destroy; override;
  end;

  TThreadsInThreadsMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Label1: TLabel;
    Memo1: TMemo;
    Panel2: TPanel;
    DLB: TDirectoryListBox;
    Label3: TLabel;
    Panel4: TPanel;
    ThumbView: TScrollbox;
    Label2: TLabel;
    TransparencyGroup: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure ThumbViewResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DLBChange(Sender: TObject);
    procedure ThumbViewMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
    procedure TransparentClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    Thumblist: TThumblist;
    ThumbsChanging: boolean;
    CurDirectory: string;
    TimeLoad, TimeResample: integer;

    // thread pool used in the thread creating the thumb images
    ThreadpoolLower, ThreadpoolUpper: TResamplingThreadPool;

    // thread generating the bitmaps for the thumbs
    MakeThumbsThreadLower, MakeThumbsThreadUpper: TMakeThumbsThread;

    // event handler for click on any thumb, shows the picture in a larger window
    procedure ThumbClick(Sender: TObject);

    // respond to change of directory and wake up the MakeThumbsThread
    procedure MakeNewThumbs;

    procedure ThreadDone(Sender: TObject);
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  ThreadsInThreadsMain: TThreadsInThreadsMain;

implementation

{$R *.dfm}

uses System.IOUtils, Winapi.ShlWApi, System.Math, System.Diagnostics,
  uShowPicture, uTools, System.Types;

// ThreadWIC is the TWICImage we use to load and decode the image-files for the MakeThumbsThread.
// This is much faster than using TPicture, particularly for jpeg's.
// Because TWICImage.Create is not threadsafe, we need to create
// it in the main thread. For simplicity this is done in
// initialization. One just has to be careful not to use it in
// more than one thread.
var
  ThreadWICLower, ThreadWICUpper: TWICImage;

procedure TThreadsInThreadsMain.DLBChange(Sender: TObject);
begin
  if (csLoading in ComponentState) or (csReading in ComponentState) or
    (csDestroying in ComponentState) then
    exit;
  // prevent reentry
  if ThumbsChanging then
    exit;
  ThumbsChanging := true;
  CurDirectory := DLB.Directory;
  MakeNewThumbs;
  ThumbsChanging := false;
end;

procedure TThreadsInThreadsMain.FormActivate(Sender: TObject);
begin
  SetBounds(0, 0, screen.width div 2, screen.Height);
  ShowPicture.Top := 0;
  ShowPicture.Left := width;
end;

procedure TThreadsInThreadsMain.FormCreate(Sender: TObject);
begin
  ThreadpoolLower.Initialize(min(16, TThread.ProcessorCount div 2), tpHigher);
  ThreadpoolUpper.Initialize(min(16, TThread.ProcessorCount div 2), tpHigher);
  //We don't initialize the default threadpool.
  //It will be initialized on demand when showing the first picture.
  //InitDefaultResamplingThreads;
  MakeThumbsThreadLower := TMakeThumbsThread.Create;
  MakeThumbsThreadLower.Priority := tpNormal;
  MakeThumbsThreadLower.LowerHalf := true;
  MakeThumbsThreadLower.Ready.WaitFor(Infinite);
  MakeThumbsThreadUpper := TMakeThumbsThread.Create;
  MakeThumbsThreadUpper.Priority := tpNormal;
  MakeThumbsThreadUpper.LowerHalf := false;
  MakeThumbsThreadUpper.Ready.WaitFor(Infinite);
  DLB.Directory := TPath.GetPicturesPath;
end;

procedure TThreadsInThreadsMain.FormDestroy(Sender: TObject);
begin
  MakeThumbsThreadLower.DoAbort := true;
  MakeThumbsThreadLower.Terminate;
  MakeThumbsThreadLower.Wakeup.SetEvent;
  MakeThumbsThreadLower.Free;
  MakeThumbsThreadUpper.DoAbort := true;
  MakeThumbsThreadUpper.Terminate;
  MakeThumbsThreadUpper.Wakeup.SetEvent;
  MakeThumbsThreadUpper.Free;
  Thumblist.ClearThumbs;
  ThreadpoolLower.Finalize;
  ThreadpoolUpper.Finalize;
  //We don't finalize the default threadpool.
  //It will be finalized in Finalization of uScale.
  //FinalizeDefaultResamplingThreads
end;

procedure TThreadsInThreadsMain.MakeNewThumbs;
begin
  if MakeThumbsThreadLower.Working then
    MakeThumbsThreadLower.DoAbort := true;
  if MakeThumbsThreadUpper.Working then
    MakeThumbsThreadUpper.DoAbort := true;
  // get all synchronize things out of the queue.
  Application.ProcessMessages;
  // Make sure the work of the thread is done,
  // since we are going to free the stuff it's working with.
  MakeThumbsThreadLower.Ready.WaitFor(Infinite);
  MakeThumbsThreadLower.Ready.ResetEvent;
  MakeThumbsThreadUpper.Ready.WaitFor(Infinite);
  MakeThumbsThreadUpper.Ready.ResetEvent;
  Thumblist.ThumbSize := MulDiv(screen.width div 24, Monitor.PixelsPerInch, 96);
  Thumblist.DetailsSize := MulDiv(screen.Height div 42,
    Monitor.PixelsPerInch, 96);
  Thumblist.ThumbParent := ThumbView;
  Thumblist.MakeLists(CurDirectory, '*.bmp;*.jpg;*.png;*.gif;*.tif;*.ico',
    ThumbClick);
  if Thumblist.ThumbCount > 2000 then
  begin
    ShowMessage('Too many pictures in folder!');
    MakeThumbsThreadLower.Ready.SetEvent;
    MakeThumbsThreadUpper.Ready.SetEvent;
    exit;
  end;
  // make the thumb-bitmaps 2 threads
  TimeLoad := 0;
  TimeResample := 0;
  MakeThumbsThreadLower.fThumblist := @Thumblist;
  MakeThumbsThreadLower.fThreadpool := @ThreadpoolLower;
  MakeThumbsThreadLower.OnDone := ThreadDone;
  MakeThumbsThreadLower.Transparency := (TransparencyGroup.ItemIndex > 0);

  MakeThumbsThreadUpper.fThumblist := @Thumblist;
  MakeThumbsThreadUpper.fThreadpool := @ThreadpoolUpper;
  MakeThumbsThreadUpper.OnDone := ThreadDone;
  MakeThumbsThreadUpper.Transparency := (TransparencyGroup.ItemIndex > 0);

  MakeThumbsThreadLower.Wakeup.SetEvent;
  MakeThumbsThreadUpper.Wakeup.SetEvent;
end;

procedure TThreadsInThreadsMain.ThreadDone(Sender: TObject);
var
  DoneAll: boolean;
begin
  with TMakeThumbsThread(Sender) do
  begin
    if TimeLoad = 0 then
      TimeLoad := ElapsedLoad
    else
      TimeLoad := TimeLoad + ElapsedLoad;
    if TimeResample = 0 then
      TimeResample := ElapsedResample
    else
      TimeResample := TimeResample + ElapsedResample;
  end;
  DoneAll := not(MakeThumbsThreadLower.Working or
    MakeThumbsThreadUpper.Working);
  if DoneAll then
  begin
    Memo1.Lines.Add(' ');
    Memo1.Lines.Add('Number of pictures: ' + Thumblist.ThumbCount.ToString);
    Memo1.Lines.Add('Load and decode: ' + TimeLoad.ToString+'ms');
    Memo1.Lines.Add('Resample: ' + TimeResample.ToString+'ms');
  end;

end;

procedure TThreadsInThreadsMain.ThumbClick(Sender: TObject);
var
  TH: TThumbControl;
  bm, tm: TBitmap;
  w, h, cw, ch: integer;
  Transparency: boolean;
  WIC: TWICImage;
  DoSetAlphaFormat: boolean;
begin
  if not ShowPicture.Visible then
  ShowPicture.Caption:='Wait for the default thread pool to be initialized';
  ShowPicture.Show;
  TH := TThumbControl(Sender);
  cw := ShowPicture.ClientWidth;
  ch := ShowPicture.ClientHeight;
  if ch = 0 then
    exit;
  bm := TBitmap.Create;
  try
    WIC := TWICImage.Create;
    try
      try
        WIC.LoadFromFile(Thumblist.DataList[TH.fThumbIndex].Filename);
      except
        BitBlt(ShowPicture.Canvas.Handle, 0, 0, ShowPicture.ClientWidth,
          ShowPicture.ClientHeight, 0, 0, 0, BLACKNESS);
        ShowPicture.Canvas.Font.Color := clRed;
        ShowPicture.Canvas.TextOut(30, 30, 'Image format not supported');
        exit;
      end;

      Transparency := (TransparencyGroup.ItemIndex > 0);

      // The following decodes to Bitmap with alphaformat afIgnored (no premultiply),
      // and opaque alpha-channel for .jpg and 24-bit .bmp.
      // Un-premultiplied input is always best for the resampling.
      WICToBmp(WIC, bm);

      // For these file formats we will set alphaformat:=afDefined
      // for the target, so it displays correctly with alpha-transparency.
      // For .jpg and .bmp this would be a waste of time.
      DoSetAlphaFormat := (not Transparency) and
        (WIC.ImageFormat in [TWICImageFormat.wifPng, TWICImageFormat.wifGif,
        TWICImageFormat.wifTiff, TWICImageFormat.wifOther]);
    finally
      WIC.Free;
    end;
    if bm.width > bm.Height * cw / ch then
    begin
      w := cw;
      if bm.width > 0 then
        h := round(w * bm.Height / bm.width)
      else
        h := 0;
    end
    else
    begin
      h := ch;
      if bm.Height > 0 then
        w := round(h * bm.width / bm.Height)
      else
        w := 0;
    end;
    if w * h > 0 then
    begin
      tm := TBitmap.Create;
      try
        // resample using default threadpool
        if Transparency then
        begin
          uScale.Resample(w, h, bm, tm, cfLanczos, 0, true,
            amTransparentColor, nil);
          tm.Transparent := true;
        end
        else if DoSetAlphaFormat then
          uScale.Resample(w, h, bm, tm, cfLanczos, 0, true, amPreMultiply, nil)
        else
          uScale.Resample(w, h, bm, tm, cfLanczos, 0, true, amIgnore, nil);

        // Set the alphaformat of the target for display
        if DoSetAlphaFormat then
          tm.AlphaFormat := afDefined;

        ShowPicture.Canvas.Brush.Color := ShowPicture.Color;
        ShowPicture.Canvas.FillRect(ShowPicture.ClientRect);

        // using draw to display with alpha-channel-opacity or transparency
        ShowPicture.Canvas.Draw((cw - w) div 2, (ch - h) div 2, tm);
      finally
        tm.Free;
      end;
    end;
  finally
    bm.Free;
  end;
  ShowPicture.Caption:='Shows Picture';
end;

procedure TThreadsInThreadsMain.ThumbViewMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: integer; MousePos: TPoint;
  var Handled: boolean);
begin
  ThumbView.VertScrollbar.Position := ThumbView.VertScrollbar.Position -
    WheelDelta;
  Handled := true;
end;

procedure TThreadsInThreadsMain.ThumbViewResize(Sender: TObject);
begin
  Thumblist.RedisplayThumbs;
end;

procedure TThreadsInThreadsMain.TransparentClick(Sender: TObject);
begin
  MakeNewThumbs;
end;

{ TThumblist }

procedure TThumblist.ClearThumbs;
var
  i, imax: integer;
begin
  imax := ThumbCount - 1;
  ThumbCount := 0;
  for i := 0 to imax do
  begin
    DataList[i].Bitmap.Free;
    DataList[i].ThumbControl.Free;
  end;
  SetLength(DataList, 0);
end;

function LogicalCompare(List: TStringlist; Index1, Index2: integer): integer;
begin
  Result := StrCmpLogicalW(PWideChar(List[Index1]), PWideChar(List[Index2]));
end;

procedure TThumblist.MakeLists(const aDirectory, aFileMask: string;
  const aThumbClick: TNotifyEvent);
var
  sl: TStringlist;
  PicPath, mask, SearchStr: string;
  MaskLen, MaskPos, SepPos, i: integer;
  TH: TThumbControl;
begin
  if not System.SysUtils.DirectoryExists(aDirectory) then
  begin
    raise exception.Create('Picture Directory is invalid');
    exit;
  end;
  ClearThumbs;

  PicPath := aDirectory + '\';
  sl := TStringlist.Create;
  try
    mask := aFileMask;
    MaskLen := Length(mask);
    MaskPos := 0;

    while MaskPos >= 0 do
    begin
      SepPos := Pos(';', mask, MaskPos + 1) - 1;
      if SepPos >= 0 then
        SearchStr := Copy(mask, MaskPos + 1, SepPos - MaskPos)
      else
        SearchStr := Copy(mask, MaskPos + 1, MaskLen);

      sl.AddStrings(TDirectory.GetFiles(PicPath, SearchStr,
        TSearchOption.soTopDirectoryOnly));

      if SepPos >= 0 then
      begin
        Inc(SepPos);
        if SepPos >= MaskLen then
          SepPos := -1;
      end;
      MaskPos := SepPos;
    end;

    // Natural sorting order, e.g. '7' '8' '9' '10'
    sl.CustomSort(LogicalCompare);

    SetLength(DataList, sl.Count);

    for i := 0 to sl.Count - 1 do
      DataList[i].Filename := sl.Strings[i];
  finally
    sl.Free;
  end;
  ThumbCount := Length(DataList);
  // the next part takes *forever* in case you use styles which are not high-dpi-optimized
  for i := 0 to ThumbCount - 1 do
  begin
    DataList[i].Bitmap := nil;
    TH := TThumbControl.Create(nil);
    // TH.StyleElements := [];
    TH.fThumblist := @self;
    DataList[i].ThumbControl := TH;
    TH.fThumbIndex := i;
    TH.OnClick := aThumbClick;
    DataList[i].OrgSize := Point(0, 0);
  end;

  RedisplayThumbs;
end;

procedure TThumblist.PaintThumb(Index: integer; aCanvas: TCanvas);
var
  bm: TBitmap;
  Name, Size: string;
  r: TRect;
  w, h, l, t: integer;
begin
  if (Index > ThumbCount - 1) or (Index < 0) or (not assigned(ThumbParent)) then
    exit;
  aCanvas.Pen.Color := clSilver;
  aCanvas.Brush.Style := bsClear;
  aCanvas.Rectangle(0, 0, ThumbSize, ThumbSize);
  aCanvas.Rectangle(0, ThumbSize, ThumbSize, ThumbSize + DetailsSize);
  Name := ExtractFileName(DataList[Index].Filename);
  Size := IntToStr(DataList[Index].OrgSize.x) + 'x' +
    IntToStr(DataList[Index].OrgSize.y);
  Name := Name + sLineBreak + Size;
  aCanvas.Font.Assign(ThumbParent.Font);
  aCanvas.Font.Color := clSilver;
  r := Rect(0, ThumbSize, ThumbSize, ThumbSize + DetailsSize);
  DrawText(aCanvas.Handle, PChar(Name), Length(Name), r,
    dt_Center or dt_VCenter or dt_WordBreak);
  if not assigned(DataList[Index].Bitmap) then
    exit;
  bm := DataList[Index].Bitmap;
  w := bm.width;
  h := bm.Height;
  l := (ThumbSize - w) div 2;
  t := (ThumbSize - h) div 2;
  aCanvas.Draw(l, t, bm);
end;

procedure TThumblist.RedisplayThumbs;
var
  i, Top, Left: integer;
  TC: TThumbControl;
begin
  if not assigned(ThumbParent) then
    exit;
  ThumbParent.DisableAlign;
  for i := 0 to ThumbCount - 1 do
  begin
    DataList[i].ThumbControl.Parent := nil;
  end;
  Top := 0;
  Left := 0;
  for i := 0 to ThumbCount - 1 do
  begin
    TC := DataList[i].ThumbControl;
    TC.Parent := ThumbParent;
    TC.SetBounds(Left - ThumbParent.HorzScrollbar.Position,
      Top - ThumbParent.VertScrollbar.Position, ThumbSize,
      ThumbSize + DetailsSize);
    Inc(Left, ThumbSize);
    if Left > ThumbParent.ClientWidth - ThumbSize - 30 then
    begin
      Inc(Top, ThumbSize + DetailsSize);
      Left := 0;
    end;
  end;
  ThumbParent.EnableAlign;
end;

{ TThumbControl }

procedure TThumbControl.WMPaint(var Msg: TWMPaint);
var
  c: TCanvas;
begin
  if assigned(fThumblist) then
    if Msg.DC <> 0 then
    begin
      c := TCanvas.Create;
      try
        c.Handle := Msg.DC;
        try
          fThumblist^.PaintThumb(fThumbIndex, c);
        finally
          c.Handle := 0;
        end;
      finally
        c.Free;
      end;
    end;
end;

{ TMakeThumbsThread }

constructor TMakeThumbsThread.Create;
begin
  inherited Create(false);
  Wakeup := TEvent.Create;
  Ready := TEvent.Create;
end;

destructor TMakeThumbsThread.Destroy;
begin
  Wakeup.Free;
  Ready.Free;
  inherited;
end;

procedure TMakeThumbsThread.DoMakeThumbs;
var
  i: integer;
  bm, tm: TBitmap;
  w, h, Count, imin, imax: integer;
  UpdateMin, UpdateMax: integer;
  StopLoadFromFile, StopResample: TStopwatch;
  WrongFormat, DoSetAlphaFormat: boolean;
  ThreadWIC: TWICImage;
begin
  Count := fThumblist^.ThumbCount;
  if Count = 0 then
    exit;
  if LowerHalf then
  begin
    imin := 0;
    imax := Count div 2;
    ThreadWIC := ThreadWICLower;
  end
  else
  begin
    imin := Count div 2 + 1;
    imax := Count - 1;
    ThreadWIC := ThreadWICUpper;
  end;
  UpdateMin := imin;
  StopLoadFromFile := TStopwatch.Create;
  StopResample := TStopwatch.Create;
  for i := imin to imax do
  begin
    if DoAbort then
      exit;
    WrongFormat := false;
    StopLoadFromFile.Start;
    bm := TBitmap.Create;
    try
      try
        ThreadWIC.LoadFromFile(fThumblist.DataList[i].Filename);
      except
        WrongFormat := true;
      end;

      if WrongFormat then
        fThumblist.DataList[i].Bitmap := nil
        // not really necessary, it's nil to begin with
      else
      begin
        // The following decodes to Bitmap with alphaformat afIgnored (no premultiply),
        // and opaque alpha-channel for .jpg and 24-bit .bmp.
        // Un-premultiplied input is always best for the resampling.
        WICToBmp(ThreadWIC, bm);

        // For these file formats we will set alphaformat:=afDefined
        // for the target, so it displays correctly with alpha-transparency.
        // For .jpg and .bmp this would be a waste of time.
        DoSetAlphaFormat := (not Transparency) and
          (ThreadWIC.ImageFormat in [TWICImageFormat.wifPng,
          TWICImageFormat.wifGif, TWICImageFormat.wifTiff,
          TWICImageFormat.wifOther]);

        fThumblist.DataList[i].OrgSize := Point(bm.width, bm.Height);
        if bm.width > bm.Height then
        begin
          w := fThumblist.ThumbSize - 4;
          if bm.width > 0 then
            h := round(w * bm.Height / bm.width)
          else
            h := 0;
        end
        else
        begin
          h := fThumblist.ThumbSize - 4;
          if bm.Height > 0 then
            w := round(h * bm.width / bm.Height)
          else
            w := 0;
        end;
        StopLoadFromFile.Stop;
        StopResample.Start;
        if w * h > 0 then
        begin
          tm := TBitmap.Create;

          // resample using a custom threadpool and setting the highest quality
          if Transparency then
          begin
            uScale.Resample(w, h, bm, tm, cfLanczos, 0, true,
              amTransparentColor, fThreadpool);
            tm.Transparent := true;
          end
          else if DoSetAlphaFormat then
            uScale.Resample(w, h, bm, tm, cfLanczos, 0, true, amPreMultiply,
              fThreadpool)
          else
            uScale.Resample(w, h, bm, tm, cfLanczos, 0, true, amIgnore,
              fThreadpool);

          if DoSetAlphaFormat then
            tm.AlphaFormat := afDefined;

          fThumblist.DataList[i].Bitmap := tm; // fThumblist will free it
        end;
        StopResample.Stop;
      end; // if not wrong format
    finally
      bm.Free;
    end;
    if (i mod 20 = 9) or (i = imax) then
      if not DoAbort then
      begin
        UpdateMax := i;
        TThread.Synchronize(TThread.Current,
          procedure
          var
            j: integer;
          begin
            for j := UpdateMin to UpdateMax do
              if not DoAbort then
                fThumblist.DataList[j].ThumbControl.Invalidate;
          end);
        UpdateMin := UpdateMax + 1;
      end;
  end; // for i

  if not DoAbort then
  begin
    ElapsedLoad := StopLoadFromFile.ElapsedMilliseconds;
    ElapsedResample := StopResample.ElapsedMilliseconds;
    Working := false;
    If assigned(OnDone) then
      TThread.Synchronize(TThread.Current,
        procedure
        begin
          OnDone(self);
        end);
  end;
end;

procedure TMakeThumbsThread.Execute;
begin
  While not terminated do
  begin
    Ready.SetEvent;
    Wakeup.WaitFor(Infinite);
    if not terminated then
    begin
      Wakeup.ResetEvent;
      DoAbort := false;
      Working := true;
      DoMakeThumbs;
      Working := false;
    end;
  end; // while not terminated
end;

initialization

ThreadWICLower := TWICImage.Create;
ThreadWICUpper := TWICImage.Create;
ReportMemoryLeaksOnShutDown := true;

finalization

ThreadWICLower.Free;
ThreadWICUpper.Free;

end.
