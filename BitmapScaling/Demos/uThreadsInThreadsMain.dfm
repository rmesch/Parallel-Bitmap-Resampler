object ThreadsInThreadsMain: TThreadsInThreadsMain
  Left = 0
  Top = 0
  Caption = 'ThreadsInThreadsMain'
  ClientHeight = 486
  ClientWidth = 766
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 153
    Top = 106
    Width = 2
    Height = 380
    ExplicitLeft = 173
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 766
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
      Caption = 'c:\...\embarcadero\studio\21.0\bin'
      Layout = tlCenter
      ExplicitLeft = -2
      ExplicitTop = -3
      ExplicitHeight = 63
    end
    object Label3: TLabel
      AlignWithMargins = True
      Left = 188
      Top = 4
      Width = 574
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
      ExplicitTop = 3
    end
  end
  object Memo1: TMemo
    Left = 600
    Top = 106
    Width = 166
    Height = 380
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
    Height = 380
    Align = alLeft
    Caption = 'Panel2'
    TabOrder = 2
    object DLB: TDirectoryListBox
      Left = 1
      Top = 1
      Width = 151
      Height = 378
      Align = alClient
      DirLabel = Label1
      TabOrder = 0
      OnChange = DLBChange
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 65
    Width = 766
    Height = 41
    Align = alTop
    TabOrder = 3
    object Label2: TLabel
      Left = 1
      Top = 1
      Width = 152
      Height = 26
      Align = alLeft
      Alignment = taCenter
      Caption = 'In this ancient tree you pick directories by double-clicking'
      Layout = tlCenter
      WordWrap = True
    end
    object TransparencyGroup: TRadioGroup
      Left = 296
      Top = 1
      Width = 469
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
  end
  object ThumbView: TScrollBox
    Left = 155
    Top = 106
    Width = 445
    Height = 380
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
