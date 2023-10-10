unit uThreadsInThreadsFMX;

//
// Important routines: TMakeThumbsThread.DoMakeThumbs,
// TThreadsInThreadsMain.MakeNewThumbs, TThreadsInThreadsMain.ThumbClick.
//
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.Layouts,
  FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.TreeView, System.ImageList,
  FMX.ImgList, uDirectoryTreeFMX, System.SyncObjs, uScaleFMX, uScaleCommon,
  FMX.ListBox, System.Diagnostics;

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
    ThumbParent: TVertScrollbox;
    DataList: Tarray<TThumbData>;
    OnThumbClick: TNotifyEvent;
    ScreenScale: single;
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
  protected
    procedure Paint; override;
  end;

  TMakeThumbsThread = class(TThread)
  private
    procedure DoMakeThumbs;
  protected
    procedure Execute; override;
  public
    DoAbort, Working: boolean;
    fThumblist: PThumblist;
    fThreadpool: PResamplingThreadpool;
    Transparency: boolean;
    LowerHalf: boolean;
    ThreadingIndex: integer;
    Ready, Wakeup: TEvent;
    ElapsedLoad, ElapsedResample: int64;
    OnDone: TNotifyEvent;
    SceneScale: single;
    DoSharpen: boolean;
    constructor Create;
    destructor Destroy; override;
  end;

  TThreadsInThreadsFMXMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Memo1: TMemo;
    Rectangle1: TRectangle;
    ThumbView: TVertScrollbox;
    Splitter1: TSplitter;
    ImageList1: TImageList;
    Threading: TComboBox;
    Label1: TLabel;
    NewRoot: TButton;
    Label2: TLabel;
    Label3: TLabel;
    ThumbSizeBox: TComboBox;
    Sharpen: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure DirectoryTreeChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ThumbViewResize(Sender: TObject);
    procedure ThreadingChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure NewRootClick(Sender: TObject);
    procedure ThumbSizeBoxChange(Sender: TObject);
    procedure SharpenChange(Sender: TObject);
  private
    ThumbList: TThumblist;
    CurDirectory: string;
    DirectoryTree: TDirectoryTree;
    MakeThumbsThreadLower, MakeThumbsThreadUpper: TMakeThumbsThread;
    ThreadPoolLower, ThreadPoolUpper: TResamplingThreadPool;
    TimeLoad, TimeResample: integer;
    MakeThumbsTime: TStopWatch;
    ScreenScale: single;
    procedure ThumbClick(Sender: TObject);
    procedure ThreadDone(Sender: TObject);
    procedure MakeNewThumbs;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  ThreadsInThreadsFMXMain: TThreadsInThreadsFMXMain;

implementation

{$R *.fmx}

uses System.IOUtils, Winapi.ShlWApi, System.Math, uShowPictureFMX;

procedure TThreadsInThreadsFMXMain.FormCreate(Sender: TObject);
begin
  // leave 2 processors for the MakeThumbsThreads (seems better)
  ThreadPoolLower.Initialize(min(16, TThread.ProcessorCount div 2 - 1),
    tpHigher);
  ThreadPoolUpper.Initialize(min(16, TThread.ProcessorCount div 2 - 1),
    tpHigher);
  MakeThumbsThreadLower := TMakeThumbsThread.Create;
  MakeThumbsThreadLower.Priority := tpHighest;
  MakeThumbsThreadLower.LowerHalf := true;
  MakeThumbsThreadLower.fThreadpool := @ThreadPoolLower;
  MakeThumbsThreadLower.Ready.WaitFor(Infinite);
  MakeThumbsThreadUpper := TMakeThumbsThread.Create;
  MakeThumbsThreadUpper.Priority := tpHighest;
  MakeThumbsThreadUpper.LowerHalf := false;
  MakeThumbsThreadLower.fThreadpool := @ThreadPoolUpper;
  MakeThumbsThreadUpper.Ready.WaitFor(Infinite);
  MakeThumbsTime := TStopWatch.Create;
  DirectoryTree := TDirectoryTree.Create(self);
  DirectoryTree.Parent := Panel3;
  DirectoryTree.Align := TAlignLayout.Client;
  DirectoryTree.Images := ImageList1;
  DirectoryTree.OnChange := DirectoryTreeChange;
  DirectoryTree.AutoHide := false;
  DirectoryTree.NewRootFolder(TPath.GetPicturesPath);
end;

procedure TThreadsInThreadsFMXMain.FormDestroy(Sender: TObject);
begin
  MakeThumbsThreadLower.DoAbort := true;
  MakeThumbsThreadUpper.DoAbort := true;
  Application.ProcessMessages;
  MakeThumbsThreadLower.Terminate;
  MakeThumbsThreadLower.Wakeup.SetEvent;
  MakeThumbsThreadLower.Free;
  MakeThumbsThreadUpper.Terminate;
  MakeThumbsThreadUpper.Wakeup.SetEvent;
  MakeThumbsThreadUpper.Free;
  ThreadPoolLower.Finalize;
  ThreadPoolUpper.Finalize;
  ThumbList.ClearThumbs;
end;

procedure TThreadsInThreadsFMXMain.FormShow(Sender: TObject);
begin
  SetBounds(0, 0, round(Screen.Width / 2), round(Screen.Height));
  ShowPicture.Left := self.Width + 10;
  ShowPicture.Top := 0;
  ShowPicture.Width := self.Width;
  ShowPicture.Height := self.Height div 2;
end;

const
  ThumbSizes: array [0 .. 2] of integer = (120, 180, 240);

procedure TThreadsInThreadsFMXMain.MakeNewThumbs;
var
  ScreenDisplay: TDisplay;
begin
  if MakeThumbsThreadLower.Working then
    MakeThumbsThreadLower.DoAbort := true;
  if MakeThumbsThreadUpper.Working then
    MakeThumbsThreadUpper.DoAbort := true;
  // get all synchronize things out of the queue.
  Application.ProcessMessages;
  // Make sure the work of the threads is done,
  // since we are going to free the stuff they're working with.
  MakeThumbsThreadLower.Ready.WaitFor(Infinite);
  MakeThumbsThreadLower.Ready.ResetEvent;
  MakeThumbsThreadUpper.Ready.WaitFor(Infinite);
  MakeThumbsThreadUpper.Ready.ResetEvent;
  ScreenDisplay := Screen.DisplayFromForm(self);
  ScreenScale := ScreenDisplay.Scale;
  ThumbList.ScreenScale := ScreenScale;
  ThumbList.ThumbSize := ThumbSizes[ThumbSizeBox.ItemIndex];
  ThumbList.DetailsSize := 46;
  ThumbList.ThumbParent := ThumbView;
  ThumbList.MakeLists(CurDirectory, '*.bmp;*.jpg;*.png;*.gif;*.tif;*.ico',
    ThumbClick);
  if ThumbList.ThumbCount > 2000 then
  begin
    ShowMessage('Too many pictures in folder!');
    MakeThumbsThreadLower.Ready.SetEvent;
    MakeThumbsThreadUpper.Ready.SetEvent;
    exit;
  end;
  // make the thumb-bitmaps 2 threads
  MakeThumbsThreadLower.fThumblist := @ThumbList;
  MakeThumbsThreadLower.OnDone := ThreadDone;
  MakeThumbsThreadLower.ThreadingIndex := Threading.ItemIndex;
  MakeThumbsThreadLower.SceneScale := ScreenScale;
  MakeThumbsThreadLower.DoSharpen := Sharpen.IsChecked;

  MakeThumbsThreadUpper.fThumblist := @ThumbList;
  MakeThumbsThreadUpper.OnDone := ThreadDone;
  MakeThumbsThreadUpper.ThreadingIndex := Threading.ItemIndex;
  MakeThumbsThreadUpper.SceneScale := ScreenScale;
  MakeThumbsThreadUpper.DoSharpen := Sharpen.IsChecked;

  TimeLoad := 0;
  TimeResample := 0;
  MakeThumbsTime.Reset;
  MakeThumbsTime.Start;
  MakeThumbsThreadLower.Wakeup.SetEvent;
  MakeThumbsThreadUpper.Wakeup.SetEvent;
end;

procedure TThreadsInThreadsFMXMain.NewRootClick(Sender: TObject);
var
  LDirectory: String;
begin
  if SelectDirectory('Pick Root Folder', '', LDirectory) then
  begin
    DirectoryTree.NewRootFolder(LDirectory);
  end;
end;


procedure TThreadsInThreadsFMXMain.SharpenChange(Sender: TObject);
begin
  MakeNewThumbs;
end;

procedure TThreadsInThreadsFMXMain.ThreadDone(Sender: TObject);
var
  DoneAll: boolean;
  PercLoad, PercResample, Total: integer;
begin
  with TMakeThumbsThread(Sender) do
  begin
    TimeLoad := TimeLoad + ElapsedLoad;
    TimeResample := TimeResample + ElapsedResample;
  end;
  DoneAll := not(MakeThumbsThreadLower.Working or
    MakeThumbsThreadUpper.Working);
  if DoneAll then
  begin
    MakeThumbsTime.Stop;
    Total := TimeLoad + TimeResample;
    if Total > 0 then
    begin
      PercLoad := round(100 * TimeLoad / Total);
      PercResample := round(100 * TimeResample / Total);
    end
    else
    begin
      PercLoad := 0;
      PercResample := 0;
    end;
    Memo1.Lines.Add(' ');
    Memo1.Lines.Add('Number of pictures: ' + ThumbList.ThumbCount.ToString);
    Memo1.Lines.Add('Time until done: ' + MakeThumbsTime.ElapsedMilliseconds.
      ToString + ' ms');
    Memo1.Lines.Add('Load and decode: ' + PercLoad.ToString + ' %');
    Memo1.Lines.Add('Resample: ' + PercResample.ToString + ' %');
  end;
end;

procedure TThreadsInThreadsFMXMain.ThreadingChange(Sender: TObject);
begin
  MakeNewThumbs;
end;

procedure TThreadsInThreadsFMXMain.ThumbClick(Sender: TObject);
var
  i: integer;
begin
  i := TThumbControl(Sender).fThumbIndex;
  ShowPicture.Show;
  ShowPicture.Image1.Bitmap.LoadFromFile(ThumbList.DataList[i].Filename);
end;

procedure TThreadsInThreadsFMXMain.ThumbSizeBoxChange(Sender: TObject);
begin
  MakeNewThumbs;
end;

procedure TThreadsInThreadsFMXMain.ThumbViewResize(Sender: TObject);
begin
  ThumbList.RedisplayThumbs;
end;

procedure TThreadsInThreadsFMXMain.DirectoryTreeChange(Sender: TObject);
begin
  CurDirectory := DirectoryTree.GetFullFolderName
    (TTreeViewItem(DirectoryTree.Selected));
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
  for i := 0 to ThumbCount - 1 do
  begin
    DataList[i].Bitmap := nil;
    TH := TThumbControl.Create(nil);
    TH.fThumblist := @self;
    DataList[i].ThumbControl := TH;
    TH.fThumbIndex := i;
    TH.OnClick := aThumbClick;
    DataList[i].OrgSize := Point(0, 0);
  end;
  RedisplayThumbs;
  ThumbParent.Repaint;
end;

procedure TThumblist.PaintThumb(Index: integer; aCanvas: TCanvas);
var
  bm: TBitmap;
  Name, Size: string;
  w, h, l, t: single;
  DrawColor: TAlphaColor;
begin
  if (Index > ThumbCount - 1) or (Index < 0) or (not assigned(ThumbParent)) then
    exit;
  DrawColor := TAlphaColorRec.Silver;
  aCanvas.Stroke.Color := DrawColor;
  aCanvas.DrawRect(RectF(0, 0, ThumbSize, ThumbSize), 1);
  aCanvas.DrawRect(RectF(0, ThumbSize, ThumbSize, ThumbSize + DetailsSize), 1);
  Name := ExtractFilename(DataList[Index].Filename);
  Size := IntToStr(DataList[Index].OrgSize.x) + 'x' +
    IntToStr(DataList[Index].OrgSize.y);
  Name := Name + sLineBreak + Size;
  aCanvas.Fill.Color := DrawColor;
  aCanvas.FillText(RectF(0, ThumbSize, ThumbSize, ThumbSize + DetailsSize),
    Name, true, 1, [], TTextAlign.Center, TTextAlign.Center);
  if not assigned(DataList[Index].Bitmap) then
    exit;
  bm := DataList[Index].Bitmap;
  // the shenanigans with ScreenScale are here so the ThumbControl
  // displays the thumb-bitmap in original size
  w := bm.Width / ScreenScale;
  h := bm.Height / ScreenScale;
  l := (ThumbSize - w) / 2;
  t := (ThumbSize - h) / 2;
  aCanvas.DrawBitmap(bm, RectF(0, 0, bm.Width, bm.Height),
    RectF(l, t, l + w, t + h), 1, false);
end;

procedure TThumblist.RedisplayThumbs;
var
  i, Top, Left: integer;
  TC: TThumbControl;
begin
  if not assigned(ThumbParent) then
    exit;
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
    TC.SetBounds(Left, Top, ThumbSize, ThumbSize + DetailsSize);
    Inc(Left, ThumbSize);
    if Left > ThumbParent.ClientWidth - ThumbSize then
    begin
      Inc(Top, ThumbSize + DetailsSize);
      Left := 0;
    end;
  end;
end;

{ TThumbControl }
procedure TThumbControl.Paint;
begin
  inherited;
  fThumblist.PaintThumb(fThumbIndex, Canvas);
end;

{ TMakeThumbsThread }
constructor TMakeThumbsThread.Create;
begin
  inherited Create(false);
  FreeOnTerminate := false;
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
  bm, am, tm: TBitmap;
  Count, imin, imax: integer;
  w, h: integer;
  StopLoadFromFile, StopResample: TStopWatch;
  WrongFormat: boolean;
  acm: TAlphaCombineMode;
  r: TRectF;
  us: TUnsharpParameters;
begin
  Count := fThumblist^.ThumbCount;
  if Count = 0 then
    exit;
  if LowerHalf then
  begin
    imin := 0;
    imax := Count div 2;
  end
  else
  begin
    imin := Count div 2 + 1;
    imax := Count - 1;
  end;
  StopLoadFromFile := TStopWatch.Create;
  StopResample := TStopWatch.Create;
  for i := imin to imax do
  begin
    if DoAbort then
      exit;
    WrongFormat := false;
    StopLoadFromFile.Start;
    bm := TBitmap.Create;
    try
      try
        bm.LoadFromFile(fThumblist.DataList[i].Filename);
      except
        WrongFormat := true;
      end;
      if WrongFormat then
        fThumblist.DataList[i].Bitmap := nil
        // not really necessary, it's nil to begin with
      else
      begin
        fThumblist.DataList[i].OrgSize := Point(bm.Width, bm.Height);
        if bm.Width > bm.Height then
        begin
          w := fThumblist.ThumbSize - 4;
          if bm.Width > 0 then
            h := round(w * bm.Height / bm.Width)
          else
            h := 0;
        end
        else
        begin
          h := fThumblist.ThumbSize - 4;
          if bm.Height > 0 then
            w := round(h * bm.Width / bm.Height)
          else
            w := 0;
        end;
        StopLoadFromFile.Stop;
        StopResample.Start;
        if w * h > 0 then
        begin
          // Make sure to resample so the size of the bitmap
          // is the same as the size displayed.
          // We want to see the thumb-bitmaps in original pixel-size,
          // and don't want FMX to do any additional scaling of its own.
          w := round(w * SceneScale);
          h := round(h * SceneScale);
          tm := TBitmap.Create;
          am := TBitmap.Create;
          try
            acm := amIndependent;
            r := RectF(0, 0, bm.Width, bm.Height);
            case ThreadingIndex of
              0:
                begin
                  am.SetSize(w, h);
                  if am.Canvas.BeginScene() then
                  begin
                    am.Canvas.Clear(0);
                    am.Canvas.DrawBitmap(bm, r, RectF(0, 0, w, h), 1, false);
                    am.Canvas.EndScene;
                  end;
                end;
              // Resample setting bicubic quality, better quality than TCanvas.DrawBitmap
              3:
                ZoomResample(w, h, bm, am, r, cfBicubic, 0, acm);
              1:
                ZoomResampleParallelThreads(w, h, bm, am, r, cfBicubic, 0, acm,
                  fThreadpool);
              2:
                ZoomResampleParallelTasks(w, h, bm, am, r, cfBicubic, 0, acm);
            end;
            if DoSharpen then
            begin
              us.AutoValues(w, h);
              UnsharpMaskParallel(am, tm, us, acm, fThreadpool);
            end
            else
              tm.Assign(am);
          finally
            am.Free;
          end;
          fThumblist.DataList[i].Bitmap := tm;
          // fThumblist will free it
        end;
        StopResample.Stop;
      end; // if not wrong format
    finally
      bm.Free;
    end;
    if (i mod 10 = 9) or (i = imax) then
      if not DoAbort then
      begin
        TThread.ForceQueue(nil,
          procedure
          begin
            fThumblist.ThumbParent.Repaint;
          end);
      end;
  end; // for i
  if not DoAbort then
  begin
    ElapsedLoad := StopLoadFromFile.ElapsedMilliseconds;
    ElapsedResample := StopResample.ElapsedMilliseconds;
    Working := false;
    if assigned(OnDone) then
      TThread.Queue(nil,
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

Initialization

ReportMemoryLeaksOnShutDown := true;

end.
