object DemoMain: TDemoMain
  Left = 0
  Top = 0
  Caption = 'DemoMain'
  ClientHeight = 561
  ClientWidth = 935
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBtnText
  Font.Height = -11
  Font.Name = 'Segoe UI Semibold'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 476
    Top = 0
    Width = 4
    Height = 561
    ExplicitLeft = 305
    ExplicitHeight = 386
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 476
    Height = 561
    Align = alLeft
    Caption = 'Panel1'
    TabOrder = 0
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 474
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
        Left = 264
        Top = 1
        Width = 209
        Height = 70
        Align = alRight
        Caption = 'Source Display Options'
        ItemIndex = 2
        Items.Strings = (
          'Add Alpha-Channel'
          'Ignore Alpha'
          'Leave Original Alpha'
          'Transparency by TransparentColor')
        TabOrder = 1
        OnClick = AlphaChannelClick
        ExplicitTop = -2
      end
      object GroupBox4: TGroupBox
        Left = 153
        Top = 1
        Width = 111
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
      Top = 523
      Width = 474
      Height = 37
      Align = alBottom
      BevelEdges = []
      TabOrder = 1
      object OriginalSize: TLabel
        Left = 12
        Top = 2
        Width = 46
        Height = 13
        Caption = 'Original: '
      end
      object Label7: TLabel
        Left = 131
        Top = 1
        Width = 342
        Height = 35
        Align = alRight
        AutoSize = False
        Caption = 
          'Hold down the right mouse button over an image to see the alpha-' +
          'channel, hold down the left button to see the BGR-channels'
        WordWrap = True
      end
    end
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 73
      Width = 474
      Height = 450
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
    Left = 480
    Top = 0
    Width = 455
    Height = 561
    Align = alClient
    TabOrder = 1
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 453
      Height = 72
      Align = alTop
      TabOrder = 0
      object GroupBox2: TGroupBox
        Left = 1
        Top = 1
        Width = 194
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
        Left = 312
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
        Left = 195
        Top = 1
        Width = 117
        Height = 70
        Align = alClient
        Caption = 'Filter and Threading'
        TabOrder = 2
        object Filters: TComboBox
          Left = 6
          Top = 16
          Width = 100
          Height = 21
          Style = csDropDownList
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
          Width = 100
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 1
          Text = 'No Threading'
          OnChange = ThreadingChange
          Items.Strings = (
            'No Threading'
            'Parallel Threads'
            'Parallel Tasks')
        end
      end
    end
    object Panel7: TPanel
      Left = 1
      Top = 73
      Width = 453
      Height = 487
      Align = alClient
      Caption = 'Panel7'
      TabOrder = 1
      object Splitter2: TSplitter
        Left = 1
        Top = 233
        Width = 451
        Height = 3
        Cursor = crVSplit
        Align = alTop
        ExplicitTop = 42
        ExplicitWidth = 283
      end
      object Panel8: TPanel
        Left = 1
        Top = 1
        Width = 451
        Height = 232
        Align = alTop
        Caption = 'Panel8'
        TabOrder = 0
        object ScrollBox2: TScrollBox
          Left = 1
          Top = 1
          Width = 449
          Height = 191
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
          Top = 192
          Width = 449
          Height = 39
          Align = alBottom
          TabOrder = 1
          object Time: TLabel
            Left = 256
            Top = 2
            Width = 25
            Height = 13
            Caption = 'Time'
          end
          object Label5: TLabel
            Left = 3
            Top = 2
            Width = 171
            Height = 13
            Caption = 'Result using Routines from uScale'
          end
          object Label8: TLabel
            Left = 3
            Top = 19
            Width = 143
            Height = 13
            Caption = 'Filter-Radius [% of Default]: '
          end
          object Radius: TLabel
            Left = 271
            Top = 21
            Width = 34
            Height = 13
            Caption = 'Radius'
          end
          object RadiusPercent: TSpinEdit
            Left = 152
            Top = 16
            Width = 57
            Height = 22
            MaxValue = 200
            MinValue = 10
            TabOrder = 0
            Value = 100
          end
          object Apply: TButton
            Left = 215
            Top = 16
            Width = 50
            Height = 21
            Caption = 'Apply'
            TabOrder = 1
            OnClick = ApplyClick
          end
        end
      end
      object Panel9: TPanel
        Left = 1
        Top = 236
        Width = 451
        Height = 250
        Align = alClient
        Caption = 'Panel9'
        TabOrder = 1
        object ScrollBox3: TScrollBox
          Left = 1
          Top = 1
          Width = 449
          Height = 209
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
          Top = 210
          Width = 449
          Height = 39
          Align = alBottom
          TabOrder = 1
          object TimeWIC: TLabel
            Left = 256
            Top = 2
            Width = 25
            Height = 13
            Caption = 'Time'
          end
          object Label6: TLabel
            Left = 8
            Top = 2
            Width = 229
            Height = 13
            Caption = 'Result using WICImage bicubic as a reference'
          end
          object Label4: TLabel
            Left = 8
            Top = 18
            Width = 367
            Height = 13
            Caption = 
              'Independent resampling, threading and transparency are not suppo' +
              'rted.'
          end
        end
      end
    end
  end
  object OPD: TOpenPictureDialog
    Filter = 
      'Alle (*.gif;*.jpg;*.jpeg;*.png;*.bmp;*.ico;*.tif;*.tiff)|*.gif;*' +
      '.jpg;*.jpeg;*.png;*.bmp;*.ico;*.tif;*.tiff|GIF-Bild (*.gif)|*.gi' +
      'f|JPEG-Grafikdatei (*.jpg)|*.jpg|JPEG-Grafikdatei (*.jpeg)|*.jpe' +
      'g|Portable Network Graphics (*.png)|*.png|Bitmaps (*.bmp)|*.bmp|' +
      'Symbole (*.ico)|*.ico|Erweiterte Metadateien (*.emf)|*.emf|Metad' +
      'ateien (*.wmf)|*.wmf|TIFF-Grafiken (*.tif)|*.tif|TIFF-Grafiken (' +
      '*.tiff)|*.tiff'
    Left = 137
    Top = 105
  end
end
