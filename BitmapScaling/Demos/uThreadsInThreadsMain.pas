unit uThreadsInThreadsMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.FileCtrl, Vcl.ExtCtrls,
  System.Generics.Collections, uScale, System.SyncObjs;

type

  TThumbControl = class;

  TThumblist = record
    ThumbCount: integer;
    ThumbSize, DetailsSize: integer;
    ThumbParent: TScrollbox;
    FileList: TList<string>;
    BitmapList: TList<TBitmap>;
    ControlList: TList<TThumbControl>;
    OnThumbClick: TNotifyEvent;
    procedure MakeLists(const aDirectory, aFileMask: string;
      const aThumbClick: TNotifyEvent);
    procedure ClearThumbs;
    procedure PaintThumb(Index: integer; aCanvas: TCanvas);
    procedure RedisplayThumbs;
  end;

  PThumblist = ^TThumblist;

  TThumbControl = class(TGraphicControl)
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
    MessageMemo: TMemo;
    fThumblist: PThumblist;
    fThreadpool: PResamplingThreadpool;
    Ready, Wakeup: TEvent;
    constructor Create;
    destructor Destroy; override;
  end;

  TThreadsInThreadsMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    ThumbView: TScrollbox;
    Label1: TLabel;
    Memo1: TMemo;
    Panel2: TPanel;
    DLB: TDirectoryListBox;
    Panel3: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ThumbViewResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DLBChange(Sender: TObject);
    procedure ThumbViewMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
  private
    fThumblist: TThumblist;
    fThumbsChanging: boolean;
    fCurDirectory: string;

    // thread pool used in the thread creating the thumb images
    fThreadpool: TResamplingThreadPool;

    // thread generating the bitmaps for the thumbs
    MakeThumbsThread: TMakeThumbsThread;

    // event handler for click on any thumb, shows the picture in a larger window
    procedure OnThumbClick(Sender: TObject);

    //respond to change of directory and wake up the MakeThumbsThread
    procedure MakeNewThumbs;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  ThreadsInThreadsMain: TThreadsInThreadsMain;

implementation

{$R *.dfm}

uses System.IOUtils, Winapi.ShlWApi, System.Math, System.Diagnostics,
  uShowPicture;

var
  // we use a TWICImage for loading and decoding
  // the images. Much faster than Graphics.TPicture,
  // at least under WIN32.
  // But TWICImage.Create is not threadsafe,
  // so we create it in the main thread in initialization
  // now of course we can use WICSource only in one thread.
  WICSource: TWICImage;

procedure TThreadsInThreadsMain.DLBChange(Sender: TObject);
begin
  if (csLoading in ComponentState) or (csReading in ComponentState) or
    (csDestroying in ComponentState) then
    exit;
  //prevent reentry
  if fThumbsChanging then
    exit;
  fThumbsChanging:=true;
  fCurDirectory:=DLB.Directory;
  MakeNewThumbs;
  fThumbsChanging:=false;
end;

procedure TThreadsInThreadsMain.FormCreate(Sender: TObject);
begin
  fThreadpool.Initialize(min(16, TThread.ProcessorCount), tpHigher);
  MakeThumbsThread := TMakeThumbsThread.Create;
  MakeThumbsThread.Priority := tpHigher;
  MakeThumbsThread.Ready.WaitFor(Infinite);
  DLB.Directory := TPath.GetPicturesPath;
end;

{ TThumblist }

procedure TThumblist.ClearThumbs;
var
  i, imax: integer;
begin
  imax := ThumbCount - 1;
  ThumbCount := 0;
  if assigned(FileList) then
    FileList.Clear;
  FreeAndNil(FileList);
  for i := 0 to imax do
  begin
    FreeAndNil(BitmapList[i]);
    ControlList[i].Parent := nil;
    FreeAndNil(ControlList[i]);
  end;
  if assigned(BitmapList) then
    BitmapList.Clear;
  FreeAndNil(BitmapList);
  if assigned(ControlList) then
    ControlList.Clear;
  FreeAndNil(ControlList);
  ThumbCount := 0;
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
  FileList := TList<string>.Create;
  ControlList := TList<TThumbControl>.Create;
  BitmapList := TList<TBitmap>.Create;

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

    for i := 0 to sl.Count - 1 do
      FileList.add(sl.Strings[i]);
  finally
    sl.free;
  end;
  ThumbCount := FileList.Count;
  // the next part takes *forever* in case you use styles
  for i := 0 to ThumbCount - 1 do
  begin
    BitmapList.add(nil);
    TH := TThumbControl.Create(nil);
    TH.StyleElements := [];
    TH.fThumblist := @self;
    ControlList.add(TH);
    TH.fThumbIndex := i;
    TH.OnClick := aThumbClick;
  end;

  RedisplayThumbs;
end;

type
  TCrack = class(TWinControl);

procedure TThumblist.PaintThumb(Index: integer; aCanvas: TCanvas);
var
  bm: TBitmap;
  Name: string;
  r: TRect;
begin
  if (Index > ThumbCount - 1) or (Index < 0) or (not assigned(ThumbParent)) then
    exit;
  aCanvas.Pen.Color := clSilver;
  aCanvas.Brush.Style := bsClear;
  aCanvas.Rectangle(0, 0, ThumbSize, ThumbSize);
  aCanvas.Rectangle(0, ThumbSize, ThumbSize, ThumbSize + DetailsSize);
  Name := ExtractFileName(FileList[Index]);
  aCanvas.Font.Assign(TCrack(ThumbParent).Font);
  r := Rect(0, ThumbSize, ThumbSize, ThumbSize + DetailsSize);
  DrawText(aCanvas.Handle, PChar(Name), Length(Name), r,
    dt_Center or dt_VCenter or dt_WordBreak);
  if not assigned(BitmapList[Index]) then
    exit;
  bm := BitmapList[Index];
  BitBlt(aCanvas.Handle, (ThumbSize - bm.Width) div 2, (ThumbSize - bm.Height)
    div 2, bm.Width, bm.Height, bm.Canvas.Handle, 0, 0, SRCCopy);
end;

procedure TThumblist.RedisplayThumbs;
var
  i, top, left: integer;
begin
  if not assigned(ThumbParent) then
    exit;
  ThumbParent.DisableAlign;
  for i := 0 to ThumbCount - 1 do
  begin
    ControlList[i].Parent := nil;
  end;
  top := 0;
  left := 0;
  for i := 0 to ThumbCount - 1 do
  begin
    ControlList[i].Parent := ThumbParent;
    ControlList[i].SetBounds(left - ThumbParent.HorzScrollbar.Position,
      top - ThumbParent.VertScrollbar.Position, ThumbSize,
      ThumbSize + DetailsSize);
    Inc(left, ThumbSize);
    if left > ThumbParent.ClientWidth - ThumbSize - 30 then
    begin
      Inc(top, ThumbSize + DetailsSize);
      left := 0;
    end;
  end;
  ThumbParent.EnableAlign;
end;

{ TThumbControl }

procedure TThumbControl.Paint;
begin
  inherited;
  if assigned(fThumblist) then
    fThumblist^.PaintThumb(fThumbIndex, Canvas);
end;

procedure TThreadsInThreadsMain.FormDestroy(Sender: TObject);
begin
  MakeThumbsThread.DoAbort := true;
  MakeThumbsThread.Terminate;
  MakeThumbsThread.Wakeup.SetEvent;
  MakeThumbsThread.free;
  fThumblist.ClearThumbs;
  fThreadpool.Finalize;
end;

procedure TThreadsInThreadsMain.MakeNewThumbs;
begin
  if MakeThumbsThread.Working then
    MakeThumbsThread.DoAbort := true;
  Application.ProcessMessages;
  MakeThumbsThread.Ready.WaitFor(Infinite);
  MakeThumbsThread.Ready.ResetEvent;
  fThumblist.ThumbSize := Screen.Width div 12;
  fThumblist.DetailsSize := Screen.Height div 21;
  fThumblist.ThumbParent := ThumbView;
  fThumblist.MakeLists(fCurDirectory, '*.bmp;*.jpg;*.png', OnThumbClick);
  ThumbView.Invalidate;
  // make the thumb-bitmaps in a thread
  MakeThumbsThread.fThumblist := @fThumblist;
  MakeThumbsThread.fThreadpool := @fThreadpool;
  MakeThumbsThread.MessageMemo := Memo1;
  MakeThumbsThread.Wakeup.SetEvent;
end;

procedure TThreadsInThreadsMain.OnThumbClick(Sender: TObject);
var
  TH: TThumbControl;
  WIC: TWICImage;
  bm, tm: TBitmap;
  w, h, cw, ch: integer;
begin
  ShowPicture.Show;
  TH := TThumbControl(Sender);
  cw := ShowPicture.ClientWidth;
  ch := ShowPicture.ClientHeight;
  if ch = 0 then
    exit;
  WIC := TWICImage.Create;
  try
    WIC.LoadFromFile(fThumblist.FileList[TH.fThumbIndex]);
    bm := TBitmap.Create;
    try
      bm.Assign(WIC);
      if bm.Width > bm.Height * cw / ch then
      begin
        w := cw;
        if bm.Width > 0 then
          h := round(w * bm.Height / bm.Width)
        else
          h := 0;
      end
      else
      begin
        h := ch;
        if bm.Height > 0 then
          w := round(h * bm.Width / bm.Height)
        else
          w := 0;
      end;
      if w * h > 0 then
      begin
        tm := TBitmap.Create;
        try
          // resample using default threadpool
          uScale.Resample(w, h, bm, tm, cfLanczos, 0, true, amIgnore, nil);
          BitBlt(ShowPicture.Canvas.Handle, 0, 0, cw, ch, 0, 0, 0, BLACKNESS);
          BitBlt(ShowPicture.Canvas.Handle, (cw - w) div 2, (ch - h) div 2, w,
            h, tm.Canvas.Handle, 0, 0, SRCCopy);
        finally
          tm.free;
        end;
      end;
    finally
      bm.free;
    end;
  finally
    WIC.free;
  end;
end;

procedure TThreadsInThreadsMain.ThumbViewMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: integer; MousePos: TPoint;
  var Handled: boolean);
begin
  ThumbView.VertScrollbar.Position := ThumbView.VertScrollbar.Position -
    WheelDelta;
end;

procedure TThreadsInThreadsMain.ThumbViewResize(Sender: TObject);
begin
  fThumblist.RedisplayThumbs;
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
  Wakeup.free;
  Ready.free;
  inherited;
end;

procedure TMakeThumbsThread.DoMakeThumbs;
var
  i: integer;
  bm, tm: TBitmap;
  w, h, Count: integer;
  UpdateMin, UpdateMax: integer;
  StopLoadFromFile, StopResample: TStopwatch;
begin
  Count := fThumblist^.ThumbCount;
  StopLoadFromFile := TStopwatch.Create;
  StopResample := TStopwatch.Create;
  UpdateMin := 0;
  for i := 0 to Count - 1 do
  begin
    StopLoadFromFile.Start;
    if DoAbort then
      exit;
    WICSource.LoadFromFile(fThumblist.FileList[i]);
    bm := TBitmap.Create;
    try
      bm.Assign(WICSource);
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
        tm := TBitmap.Create;

        // resample using a custom threadpool
        uScale.Resample(w, h, bm, tm, cfBicubic, 0, true, amIgnore,
          fThreadpool);
        fThumblist.BitmapList[i] := tm; // fThumblist will free it
      end;
      StopResample.Stop;
    finally
      bm.free;
    end;
    if (i mod 10 = 9) or (i = Count - 1) then
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
                fThumblist.ControlList[j].Invalidate;
          end);
        UpdateMin := UpdateMax + 1;
      end;
  end; // for i

  if not DoAbort then
    TThread.Synchronize(TThread.Current,
      procedure
      begin
        MessageMemo.Lines.add(' ');
        MessageMemo.Lines.add('Number of pictures: ' + IntToStr(Count));
        MessageMemo.Lines.add('Load and decode: ' +
          IntToStr(StopLoadFromFile.ElapsedMilliseconds) + ' ms');
        MessageMemo.Lines.add('Resample: ' +
          IntToStr(StopResample.ElapsedMilliseconds) + ' ms');
      end);
end;

procedure TMakeThumbsThread.Execute;
begin
  While not terminated do
  begin
    Ready.SetEvent;
    Working := false;
    Wakeup.WaitFor(Infinite);
    if not terminated then
    begin
      Wakeup.ResetEvent;
      DoAbort := false;
      Working := true;
      DoMakeThumbs;
    end;
  end; // while not terminated
end;

initialization

ReportMemoryLeaksOnShutDown := true;

// TWICImage.Create is not threadsafe, so
// we create the one for our thread in the main thread.
WICSource := TWICImage.Create;

finalization

WICSource.free;

end.
