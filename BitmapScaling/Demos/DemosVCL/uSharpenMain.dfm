object SharpenMain: TSharpenMain
  Left = 0
  Top = 0
  Caption = 'SharpenMain'
  ClientHeight = 461
  ClientWidth = 858
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object Panel1: TPanel
    Left = 704
    Top = 76
    Width = 154
    Height = 385
    Align = alRight
    TabOrder = 0
    DesignSize = (
      154
      385)
    object ShowRadius: TLabel
      Left = 8
      Top = 6
      Width = 64
      Height = 15
      Caption = 'ShowRadius'
    end
    object ShowAlpha: TLabel
      Left = 54
      Top = 6
      Width = 60
      Height = 15
      Caption = 'ShowAlpha'
    end
    object ShowThresh: TLabel
      Left = 104
      Top = 6
      Width = 64
      Height = 15
      Caption = 'ShowThresh'
    end
    object RadiusSlider: TTrackBar
      Left = 16
      Top = 27
      Width = 45
      Height = 186
      Anchors = [akLeft, akTop, akBottom]
      Enabled = False
      Max = 4000
      Min = 10
      Orientation = trVertical
      Frequency = 100
      Position = 200
      TabOrder = 0
      OnChange = RadiusSliderChange
    end
    object AlphaSlider: TTrackBar
      Left = 61
      Top = 27
      Width = 45
      Height = 186
      Anchors = [akLeft, akTop, akBottom]
      Enabled = False
      Max = 500
      Min = -100
      Orientation = trVertical
      Frequency = 10
      Position = 150
      TabOrder = 1
      OnChange = AlphaSliderChange
    end
    object ThreshSlider: TTrackBar
      Left = 112
      Top = 27
      Width = 45
      Height = 186
      Anchors = [akLeft, akTop, akBottom]
      Enabled = False
      Max = 50
      Orientation = trVertical
      TabOrder = 2
      OnChange = ThreshSliderChange
    end
    object GroupBox5: TGroupBox
      Left = 1
      Top = 212
      Width = 152
      Height = 172
      Align = alBottom
      Caption = 'Meaning of Parameters:'
      TabOrder = 3
      object Label5: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 18
        Width = 144
        Height = 31
        Margins.Left = 2
        Margins.Top = 1
        Margins.Right = 2
        Margins.Bottom = 1
        Align = alTop
        AutoSize = False
        Caption = 'r: Radius of Gaussian blur in pixel. Sigma=r/5.'
        WordWrap = True
      end
      object Label6: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 51
        Width = 144
        Height = 58
        Margins.Left = 2
        Margins.Top = 1
        Margins.Right = 2
        Margins.Bottom = 1
        Align = alTop
        AutoSize = False
        Caption = 
          'a: Result = a * Source + (1-a) * Blur. a > 1 sharpens. a = 0 app' +
          'lies Gaussian blur.'
        WordWrap = True
      end
      object Label7: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 111
        Width = 144
        Height = 58
        Margins.Left = 2
        Margins.Top = 1
        Margins.Right = 2
        Margins.Bottom = 1
        Align = alClient
        AutoSize = False
        Caption = 
          't: Threshhold. Filter is only applied when abs(Source - Blur) > ' +
          't * 255'
        WordWrap = True
        ExplicitTop = 116
        ExplicitHeight = 53
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 858
    Height = 76
    Align = alTop
    TabOrder = 1
    object GroupBox1: TGroupBox
      Left = 1
      Top = 1
      Width = 107
      Height = 74
      Align = alLeft
      Caption = 'Source Image'
      TabOrder = 0
      object ShowSize: TLabel
        Left = 3
        Top = 49
        Width = 49
        Height = 15
        Caption = 'ShowSize'
      end
      object LoadImage: TButton
        Left = 3
        Top = 22
        Width = 75
        Height = 25
        Caption = 'Load'
        TabOrder = 0
        OnClick = LoadImageClick
      end
    end
    object GroupBox2: TGroupBox
      Left = 108
      Top = 1
      Width = 249
      Height = 74
      Align = alLeft
      Caption = 'Resampling'
      TabOrder = 1
      object Label1: TLabel
        Left = 6
        Top = 19
        Width = 59
        Height = 15
        Caption = 'Scaling [%]'
      end
      object Label2: TLabel
        Left = 74
        Top = 20
        Width = 26
        Height = 15
        Caption = 'Filter'
      end
      object ShowNewSize: TLabel
        Left = 164
        Top = 44
        Width = 73
        Height = 15
        Caption = 'ShowNewSize'
      end
      object ScalePercent: TSpinEdit
        Left = 3
        Top = 40
        Width = 65
        Height = 24
        MaxValue = 300
        MinValue = 5
        TabOrder = 0
        Value = 100
        OnChange = ScalePercentChange
      end
      object ShowFilter: TComboBox
        Left = 74
        Top = 41
        Width = 84
        Height = 23
        ItemIndex = 2
        TabOrder = 1
        Text = 'Bicubic'
        OnChange = ScalePercentChange
        Items.Strings = (
          'Box'
          'Bilinear'
          'Bicubic'
          'Lanczos')
      end
    end
    object GroupBox3: TGroupBox
      Left = 357
      Top = 1
      Width = 185
      Height = 74
      Align = alLeft
      Caption = 'Unsharp Mask'
      TabOrder = 2
      object EnableSharpen: TCheckBox
        Left = 6
        Top = 19
        Width = 97
        Height = 17
        Caption = 'Enable'
        Checked = True
        State = cbChecked
        TabOrder = 0
        OnClick = EnableSharpenClick
      end
      object AutoSharpen: TCheckBox
        Left = 6
        Top = 42
        Width = 143
        Height = 17
        Caption = 'Automatic Parameters'
        Checked = True
        State = cbChecked
        TabOrder = 1
        OnClick = EnableSharpenClick
      end
    end
    object GroupBox4: TGroupBox
      Left = 542
      Top = 1
      Width = 185
      Height = 74
      Align = alLeft
      Caption = 'Timings [ms]'
      TabOrder = 3
      object TimeResample: TLabel
        Left = 84
        Top = 26
        Width = 77
        Height = 15
        Caption = 'TimeResample'
      end
      object TimeSharpen: TLabel
        Left = 84
        Top = 47
        Width = 69
        Height = 15
        Caption = 'TimeSharpen'
      end
      object Label3: TLabel
        Left = 13
        Top = 26
        Width = 65
        Height = 15
        Alignment = taRightJustify
        Caption = 'Resampling:'
      end
      object Label4: TLabel
        Left = 15
        Top = 47
        Width = 63
        Height = 15
        Alignment = taRightJustify
        Caption = 'Sharpening:'
      end
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 76
    Width = 704
    Height = 385
    Align = alClient
    Caption = 'Panel3'
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 357
      Top = 1
      Height = 383
      ExplicitLeft = 392
      ExplicitTop = 304
      ExplicitHeight = 100
    end
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 1
      Width = 356
      Height = 383
      HorzScrollBar.Tracking = True
      VertScrollBar.Tracking = True
      Align = alLeft
      TabOrder = 0
      ExplicitLeft = 0
      ExplicitTop = 0
      object DisplayOriginal: TImage
        Left = 0
        Top = 0
        Width = 105
        Height = 105
        AutoSize = True
      end
    end
    object ScrollBox2: TScrollBox
      Left = 360
      Top = 1
      Width = 343
      Height = 383
      HorzScrollBar.Tracking = True
      VertScrollBar.Tracking = True
      Align = alClient
      TabOrder = 1
      ExplicitLeft = 361
      ExplicitTop = 0
      object DisplaySharpened: TPaintBox
        Left = 0
        Top = 0
        Width = 105
        Height = 105
        OnClick = DisplaySharpenedClick
        OnPaint = DisplaySharpenedPaint
      end
    end
  end
  object FODImage: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Image Files'
        FileMask = '*.bmp;*.jpg;*.gif;*.png'
      end>
    Options = [fdoForceShowHidden]
    Left = 633
    Top = 312
  end
  object FSD: TFileSaveDialog
    DefaultExtension = '.bmp'
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 629
    Top = 257
  end
end
