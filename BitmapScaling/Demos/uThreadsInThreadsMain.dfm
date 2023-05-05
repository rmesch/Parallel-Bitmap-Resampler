object ThreadsInThreadsMain: TThreadsInThreadsMain
  Left = 0
  Top = 0
  Caption = 'ThreadsInThreadsMain'
  ClientHeight = 473
  ClientWidth = 782
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  StyleElements = [seFont, seClient]
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormActivate
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 153
    Top = 106
    Width = 2
    Height = 367
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 782
    Height = 65
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 178
      Height = 57
      Align = alLeft
      Alignment = taCenter
      AutoSize = False
      Caption = 'c:\...\embarcadero\studio\22.0\bin'
      Layout = tlCenter
      ExplicitHeight = 58
    end
    object Label3: TLabel
      AlignWithMargins = True
      Left = 188
      Top = 4
      Width = 590
      Height = 57
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 
        'The thumb-images are made in 2 threads which also use threaded r' +
        'esampling with a threadpool dedicated to each thread. Click on a' +
        ' thumb to see a larger picture. This is resampled in the main th' +
        'read using the default thread-pool in uScale. This should be a s' +
        'ufficient crash-test for thread safety.'
      Layout = tlCenter
      WordWrap = True
      ExplicitWidth = 591
      ExplicitHeight = 58
    end
  end
  object Memo1: TMemo
    Left = 616
    Top = 106
    Width = 166
    Height = 367
    Align = alRight
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Panel2: TPanel
    Left = 0
    Top = 106
    Width = 153
    Height = 367
    Align = alLeft
    Caption = 'Panel2'
    TabOrder = 2
    object DLB: TDirectoryListBox
      Left = 1
      Top = 20
      Width = 151
      Height = 346
      Align = alClient
      DirLabel = Label1
      TabOrder = 0
      OnChange = DLBChange
      ExplicitTop = 32
      ExplicitHeight = 334
    end
    object DriveComboBox1: TDriveComboBox
      Left = 1
      Top = 1
      Width = 151
      Height = 19
      Align = alTop
      DirList = DLB
      TabOrder = 1
      ExplicitLeft = 4
      ExplicitTop = 6
      ExplicitWidth = 145
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 65
    Width = 782
    Height = 41
    Align = alTop
    TabOrder = 3
    object Label2: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 217
      Height = 33
      Align = alLeft
      Alignment = taCenter
      Caption = 'In this ancient tree you pick directories by double-clicking'
      Layout = tlCenter
      WordWrap = True
      ExplicitHeight = 26
    end
    object TransparencyGroup: TRadioGroup
      Left = 520
      Top = 1
      Width = 261
      Height = 39
      Align = alRight
      Caption = 'Transparency'
      Columns = 2
      ItemIndex = 0
      Items.Strings = (
        'By alpha-channel'
        'By tranparent color')
      TabOrder = 0
      OnClick = TransparentClick
    end
    object Threading: TRadioGroup
      Left = 224
      Top = 1
      Width = 296
      Height = 39
      Align = alClient
      Caption = 'Parallel resampling'
      Columns = 3
      ItemIndex = 1
      Items.Strings = (
        'None'
        'Threads'
        'Tasks')
      TabOrder = 1
      OnClick = ThreadingClick
    end
  end
  object ThumbView: TScrollBox
    Left = 155
    Top = 106
    Width = 461
    Height = 367
    HorzScrollBar.Tracking = True
    VertScrollBar.Tracking = True
    Align = alClient
    Color = 3417354
    ParentColor = False
    TabOrder = 4
    OnMouseWheel = ThumbViewMouseWheel
    OnResize = ThumbViewResize
  end
end
