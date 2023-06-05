object DemoMain: TDemoMain
  Left = 0
  Top = 18
  Caption = 'DemoMain'
  ClientHeight = 510
  ClientWidth = 922
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBtnText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poDesigned
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 457
    Top = 0
    Width = 2
    Height = 510
    ExplicitLeft = 470
    ExplicitHeight = 509
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 457
    Height = 510
    Align = alLeft
    Caption = 'Panel1'
    TabOrder = 0
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 455
      Height = 72
      Align = alTop
      TabOrder = 0
      object GroupBox1: TGroupBox
        Left = 1
        Top = 1
        Width = 152
        Height = 70
        Align = alLeft
        Caption = 'Test Bitmap'
        TabOrder = 0
        object Label1: TLabel
          Left = 1
          Top = 19
          Width = 26
          Height = 13
          Caption = 'Size: '
        end
        object BitmapSize: TComboBox
          Left = 1
          Top = 36
          Width = 56
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 0
        end
        object MakeTestBitmap: TButton
          Left = 63
          Top = 36
          Width = 56
          Height = 21
          Caption = 'Make'
          TabOrder = 1
          OnClick = MakeTestBitmapClick
        end
      end
      object AlphaChannel: TRadioGroup
        Left = 245
        Top = 1
        Width = 209
        Height = 70
        Align = alRight
        Caption = 'Source Display Options'
        ItemIndex = 1
        Items.Strings = (
          'Add Alpha-Channel'
          'Ignore Alpha'
          'Leave Original Alpha'
          'Transparency by TransparentColor')
        TabOrder = 1
        OnClick = AlphaChannelClick
      end
      object GroupBox4: TGroupBox
        Left = 153
        Top = 1
        Width = 92
        Height = 70
        Align = alClient
        Caption = 'Image from File'
        TabOrder = 2
        object Load: TButton
          Left = 6
          Top = 36
          Width = 75
          Height = 21
          Caption = 'Load'
          TabOrder = 0
          OnClick = LoadClick
        end
      end
    end
    object Panel5: TPanel
      Left = 1
      Top = 468
      Width = 455
      Height = 41
      Align = alBottom
      BevelEdges = []
      TabOrder = 1
      object OriginalSize: TLabel
        Left = 12
        Top = 2
        Width = 48
        Height = 13
        Caption = 'Original: '
      end
      object Label7: TLabel
        Left = 112
        Top = 1
        Width = 342
        Height = 39
        Align = alRight
        AutoSize = False
        Caption = 
          'Hold down the right mouse button over an image to see the alpha-' +
          'channel, hold down the left button to see the BGR-channels'
        WordWrap = True
        ExplicitLeft = 125
        ExplicitTop = 6
        ExplicitHeight = 30
      end
    end
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 73
      Width = 455
      Height = 395
      HorzScrollBar.Tracking = True
      VertScrollBar.Tracking = True
      Align = alClient
      Color = 3417354
      ParentColor = False
      TabOrder = 2
      OnMouseWheel = ScrollBox1MouseWheel
      object Image1: TImage
        Left = 0
        Top = 3
        Width = 256
        Height = 256
        AutoSize = True
        OnMouseDown = Image1MouseDown
        OnMouseUp = Image1MouseUp
      end
    end
  end
  object Panel2: TPanel
    Left = 459
    Top = 0
    Width = 463
    Height = 510
    Align = alClient
    TabOrder = 1
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 461
      Height = 72
      Align = alTop
      TabOrder = 0
      object GroupBox2: TGroupBox
        Left = 1
        Top = 1
        Width = 195
        Height = 70
        Align = alLeft
        Caption = 'New Size'
        TabOrder = 0
        object Label2: TLabel
          Left = 56
          Top = 19
          Width = 12
          Height = 13
          Alignment = taCenter
          AutoSize = False
          Caption = 'x'
        end
        object Label3: TLabel
          Left = 4
          Top = 46
          Width = 31
          Height = 13
          Caption = 'Steps:'
        end
        object Width: TSpinEdit
          Left = 3
          Top = 16
          Width = 52
          Height = 22
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = WidthChange
        end
        object Height: TSpinEdit
          Left = 72
          Top = 16
          Width = 52
          Height = 22
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = HeightChange
        end
        object KeepAspect: TCheckBox
          Left = 97
          Top = 45
          Width = 91
          Height = 17
          Caption = 'Keep Aspect'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object Resize: TButton
          Left = 129
          Top = 14
          Width = 59
          Height = 25
          Caption = 'Resize'
          TabOrder = 3
          OnClick = ResizeClick
        end
        object Steps: TSpinEdit
          Left = 41
          Top = 43
          Width = 41
          Height = 22
          MaxValue = 40
          MinValue = 1
          TabOrder = 4
          Value = 1
        end
      end
      object CombineModes: TRadioGroup
        Left = 320
        Top = 1
        Width = 140
        Height = 70
        Align = alRight
        Caption = 'Alpha Combine-Mode'
        ItemIndex = 2
        Items.Strings = (
          'Independent'
          'Pre-Multiplied'
          'Ignore Alpha'
          'Preserve Transparency')
        TabOrder = 1
        OnClick = ThreadingChange
      end
      object GroupBox3: TGroupBox
        Left = 196
        Top = 1
        Width = 124
        Height = 70
        Align = alClient
        Caption = 'Filter and Threading'
        TabOrder = 2
        object Filters: TComboBox
          Left = 6
          Top = 16
          Width = 112
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 0
          Text = 'Box'
          OnChange = ThreadingChange
          Items.Strings = (
            'Box'
            'Bilinear'
            'Bicubic'
            'Lanczos')
        end
        object Threading: TComboBox
          Left = 6
          Top = 43
          Width = 112
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 1
          Text = 'No Threading'
          OnChange = ThreadingChange
          Items.Strings = (
            'No Threading'
            'Parallel Threads')
        end
      end
    end
    object Panel7: TPanel
      Left = 1
      Top = 73
      Width = 461
      Height = 436
      Align = alClient
      Caption = 'Panel7'
      TabOrder = 1
      OnResize = Panel7Resize
      object Splitter2: TSplitter
        Left = 1
        Top = 233
        Width = 459
        Height = 4
        Cursor = crVSplit
        Align = alTop
        ExplicitLeft = 0
        ExplicitTop = 232
        ExplicitWidth = 454
      end
      object Panel8: TPanel
        Left = 1
        Top = 1
        Width = 459
        Height = 232
        Align = alTop
        Caption = 'Panel8'
        TabOrder = 0
        object ScrollBox2: TScrollBox
          Left = 1
          Top = 1
          Width = 457
          Height = 190
          HorzScrollBar.Tracking = True
          VertScrollBar.Tracking = True
          Align = alClient
          Color = 3417354
          ParentColor = False
          TabOrder = 0
          OnMouseWheel = ScrollBox1MouseWheel
          object Image2: TImage
            Left = 0
            Top = 0
            Width = 105
            Height = 105
            AutoSize = True
            OnMouseDown = Image2MouseDown
            OnMouseUp = Image2MouseUp
          end
        end
        object Panel6: TPanel
          Left = 1
          Top = 191
          Width = 457
          Height = 40
          Align = alBottom
          TabOrder = 1
          object Time: TLabel
            Left = 256
            Top = 2
            Width = 28
            Height = 15
            Caption = 'Time'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBtnText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label5: TLabel
            Left = 3
            Top = 2
            Width = 176
            Height = 13
            Caption = 'Result using Routines from uScale'
          end
          object Label8: TLabel
            Left = 3
            Top = 19
            Width = 144
            Height = 13
            Caption = 'Filter-Radius [% of Default]: '
          end
          object Radius: TLabel
            Left = 250
            Top = 21
            Width = 35
            Height = 13
            Caption = 'Radius'
          end
          object RadiusPercent: TSpinEdit
            Left = 150
            Top = 16
            Width = 41
            Height = 22
            MaxValue = 200
            MinValue = 10
            TabOrder = 0
            Value = 100
          end
          object Apply: TButton
            Left = 190
            Top = 16
            Width = 50
            Height = 21
            Caption = 'Apply'
            TabOrder = 1
            OnClick = ApplyClick
          end
          object ZoomIn: TButton
            Left = 344
            Top = 3
            Width = 30
            Height = 20
            Caption = '+'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBtnText
            Font.Height = -13
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            OnClick = ZoomInClick
          end
          object ZoomOut: TButton
            Left = 380
            Top = 3
            Width = 30
            Height = 20
            Caption = '-'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBtnText
            Font.Height = -13
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
            TabOrder = 3
            OnClick = ZoomOutClick
          end
          object NoZoom: TButton
            Left = 416
            Top = 3
            Width = 30
            Height = 20
            Caption = '100%'
            TabOrder = 4
            OnClick = NoZoomClick
          end
        end
      end
      object Panel9: TPanel
        Left = 1
        Top = 237
        Width = 459
        Height = 198
        Align = alClient
        Caption = 'Panel9'
        TabOrder = 1
        object ScrollBox3: TScrollBox
          Left = 1
          Top = 1
          Width = 457
          Height = 157
          HorzScrollBar.Tracking = True
          VertScrollBar.Tracking = True
          Align = alClient
          Color = 3417354
          ParentColor = False
          TabOrder = 0
          OnMouseWheel = ScrollBox1MouseWheel
          object Image3: TImage
            Left = 0
            Top = 0
            Width = 105
            Height = 105
            AutoSize = True
            OnMouseDown = Image3MouseDown
            OnMouseUp = Image3MouseUp
          end
        end
        object Panel10: TPanel
          Left = 1
          Top = 158
          Width = 457
          Height = 39
          Align = alBottom
          TabOrder = 1
          object TimeWIC: TLabel
            Left = 256
            Top = 2
            Width = 28
            Height = 15
            Caption = 'Time'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBtnText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label6: TLabel
            Left = 8
            Top = 2
            Width = 227
            Height = 13
            Caption = 'Result using Stretch_Halftone as a reference'
          end
          object Label4: TLabel
            Left = 8
            Top = 18
            Width = 299
            Height = 13
            Caption = 'Alpha-channel-options and threading  are not supported.'
          end
        end
      end
    end
  end
  object OPD: TOpenPictureDialog
    Filter = 
      'Alle (*.jpg;*.jpeg;*.bmp;*.ico)|*.jpg;*.jpeg;*.bmp;*.ico|JPEG-Gr' +
      'afikdatei (*.jpg)|*.jpg|JPEG-Grafikdatei (*.jpeg)|*.jpeg|Bitmaps' +
      ' (*.bmp)|*.bmp|Symbole (*.ico)|*.ico'
    Left = 9
    Top = 81
  end
  object SPD: TSavePictureDialog
    Left = 9
    Top = 137
  end
end
