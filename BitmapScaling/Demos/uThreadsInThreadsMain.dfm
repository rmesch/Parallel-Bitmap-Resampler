object ThreadsInThreadsMain: TThreadsInThreadsMain
  Left = 0
  Top = 0
  Caption = 'ThreadsInThreadsMain'
  ClientHeight = 405
  ClientWidth = 766
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 173
    Top = 65
    Width = 0
    Height = 340
    ExplicitLeft = 137
    ExplicitTop = 35
    ExplicitHeight = 370
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 766
    Height = 65
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 1
      Top = 1
      Width = 178
      Height = 63
      Align = alLeft
      Alignment = taCenter
      AutoSize = False
      Caption = 'c:\...\embarcadero\studio\21.0\bin'
      Layout = tlCenter
      ExplicitHeight = 33
    end
    object Label3: TLabel
      Left = 179
      Top = 1
      Width = 586
      Height = 63
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 
        'The thumb-images are made in a thread which also uses threaded r' +
        'esampling with a threadpool dedicated to that thread. Click on a' +
        ' thumb to see a larger picture. This is resampled in the main th' +
        'read using the default thread-pool in uScale. Click while the th' +
        'umbs are still being loaded to check thread-safety.'
      Layout = tlCenter
      WordWrap = True
      ExplicitLeft = 185
      ExplicitTop = -3
    end
  end
  object ThumbView: TScrollBox
    Left = 173
    Top = 65
    Width = 427
    Height = 340
    HorzScrollBar.Tracking = True
    VertScrollBar.Tracking = True
    Align = alClient
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clSilver
    Font.Height = -9
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    StyleElements = [seBorder]
    OnMouseWheel = ThumbViewMouseWheel
    OnResize = ThumbViewResize
    ExplicitLeft = 167
    ExplicitTop = 70
  end
  object Memo1: TMemo
    Left = 600
    Top = 65
    Width = 166
    Height = 340
    Align = alRight
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 0
    Top = 65
    Width = 173
    Height = 340
    Align = alLeft
    Caption = 'Panel2'
    TabOrder = 3
    object DLB: TDirectoryListBox
      Left = 1
      Top = 44
      Width = 171
      Height = 295
      Align = alClient
      DirLabel = Label1
      TabOrder = 0
      OnChange = DLBChange
      ExplicitLeft = -4
      ExplicitTop = 84
    end
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 171
      Height = 43
      Align = alTop
      TabOrder = 1
      object Label2: TLabel
        Left = 1
        Top = 1
        Width = 169
        Height = 41
        Align = alClient
        Alignment = taCenter
        Caption = 'In this ancient tree you pick directories by double-clicking'
        Layout = tlCenter
        WordWrap = True
        ExplicitWidth = 152
        ExplicitHeight = 26
      end
    end
  end
end
