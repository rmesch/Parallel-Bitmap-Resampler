object DemoMain: TDemoMain
  Left = 0
  Top = 18
  Caption = 'DemoMain'
  ClientHeight = 509
  ClientWidth = 922
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBtnText
  Font.Height = -11
  Font.Name = 'Segoe UI Semibold'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 470
    Top = 0
    Width = 2
    Height = 509
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 470
    Height = 509
    Align = alLeft
    Caption = 'Panel1'
    TabOrder = 0
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 468
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
        object Label9: TLabel
          Left = 0
          Top = 43
          Width = 26
          Height = 13
          Caption = 'Kind:'
        end
        object BitmapSize: TComboBox
          Left = 33
          Top = 16
          Width = 56
          Height = 21
          Style = csDropDownList
          TabOrder = 0
        end
        object MakeTestBitmap: TButton
          Left = 95
          Top = 16
          Width = 56
          Height = 21
          Caption = 'Make'
          TabOrder = 1
          OnClick = MakeTestBitmapClick
        end
        object BitmapKind: TComboBox
          Left = 33
          Top = 40
          Width = 116
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 2
          Text = 'Zone-Circles'
          Items.Strings = (
            'Zone-Circles'
            'Lines and Text')
        end
      end
      object AlphaChannel: TRadioGroup
        Left = 258
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
        Width = 105
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
      Top = 471
      Width = 468
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
        Left = 125
        Top = 1
        Width = 342
        Height = 35
        Align = alRight
        AutoSize = False
        Caption = 
          'Hold down the right mouse button over an image to see the alpha-' +
          'channel, hold down the left button to see the BGR-channels'
        WordWrap = True
        ExplicitLeft = 133
        ExplicitTop = 0
        ExplicitHeight = 36
      end
    end
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 73
      Width = 468
      Height = 398
      HorzScrollBar.Tracking = True
      VertScrollBar.Tracking = True
      Align = alClient
      Color = 3417354
      ParentColor = False
      TabOrder = 2
      OnMouseWheel = ScrollBox1MouseWheel
      object Image1: TImage
        Left = 0
        Top = 0
        Width = 256
        Height = 256
        AutoSize = True
        OnMouseDown = Image1MouseDown
        OnMouseUp = Image1MouseUp
      end
    end
  end
  object Panel2: TPanel
    Left = 472
    Top = 0
    Width = 450
    Height = 509
    Align = alClient
    TabOrder = 1
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 448
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
        Left = 307
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
        Width = 111
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
            'Lanczos'
            'Mitchell'
            'Robidoux'
            'RobidouxSharp'
            'RobidouxSoft')
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
      Width = 448
      Height = 435
      Align = alClient
      Caption = 'Panel7'
      TabOrder = 1
      OnResize = Panel7Resize
      object Splitter2: TSplitter
        Left = 1
        Top = 233
        Width = 446
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
        Width = 446
        Height = 232
        Align = alTop
        Caption = 'Panel8'
        TabOrder = 0
        object ScrollBox2: TScrollBox
          Left = 1
          Top = 1
          Width = 444
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
            OnDblClick = Image2DblClick
            OnMouseDown = Image2MouseDown
            OnMouseUp = Image2MouseUp
          end
        end
        object Panel6: TPanel
          Left = 1
          Top = 191
          Width = 444
          Height = 40
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
            Left = 250
            Top = 21
            Width = 34
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
            ImageIndex = 0
            ImageName = 'search_64_h'
            Images = ImageList1
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
            ImageIndex = 0
            ImageName = 'search_64_h'
            Images = ImageList1
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
            ImageIndex = 0
            TabOrder = 4
            OnClick = NoZoomClick
          end
        end
      end
      object Panel9: TPanel
        Left = 1
        Top = 237
        Width = 446
        Height = 197
        Align = alClient
        Caption = 'Panel9'
        TabOrder = 1
        object ScrollBox3: TScrollBox
          Left = 1
          Top = 1
          Width = 444
          Height = 156
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
          Top = 157
          Width = 444
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
    Left = 9
    Top = 81
  end
  object SPD: TSavePictureDialog
    Filter = '|*.png;*.bmp'
    Left = 9
    Top = 137
  end
  object ImageList1: TImageList
    Left = 13
    Top = 201
    Bitmap = {
      494C010101000800040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000009D9E9E009D9996000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009D9E9E00C4C4C4009D9996000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000009D9E
      9E009D9E9E00D1D0D0009D999600000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000BBBBBC00BBBBBC00BBBBBC000000000000000000000000009D9E9E00AFB1
      B000C7BEC3009D99960000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000BBBABC00BBBA
      BC00D4D0CE00DDD9D500D5D0CF00B2B1B100B2B1B1009D9E9E00B8BABA009D99
      96009D9996000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000B5B5B500CAC2BC00F3EA
      E500FFFAF400FEFAF600FFF8F600F4EAE500CCC9C700BCBDBD009D9996000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000B5B5B500F7EDE300FCF6
      EF00FCF6F000FCF7F200FCF8F600FEFAF600F4E7E200B6B4B4009D9996000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000A6A3A000D3C6B800FCF3EA00FBF4
      EE00FCF4EE00FCF6F000FCF7F200FCF8F400FFF6F200D9CFCA0097918C000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000009D999600DECFC000FBEEE100FBF0
      E600FBF3EB00FCF6EF00FCF6F000FCF7F200FEF7F200E7D9D40095908A000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000096918C00D4C4B200FEF0E500FAED
      DE00FAEEE100FBF0E600FBF3EA00FCF6EE00FFF6F000DECFCA0095908A000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000095908A00FFF3E600FCF2
      E700FBEFE500FAEEE300FAF0E300FCF3E900FAEADE0095908A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000095908A00B8A79600FEF0
      E500FFF6EB00FEF6EB00FFF7EE00FCEEE200C1AFA50095908A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000095908A009590
      8A00C7B6A900D1C0B400CBB8AC0095908A0095908A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000095908A0095908A0095908A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFF000000000000FFFC000000000000
      FFF8000000000000FFE1000000000000F1C3000000000000C007000000000000
      801F000000000000801F000000000000001F000000000000001F000000000000
      001F000000000000803F000000000000803F000000000000C07F000000000000
      F1FF000000000000FFFF00000000000000000000000000000000000000000000
      000000000000}
  end
end
