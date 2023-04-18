object DemoMain: TDemoMain
  Left = 0
  Top = 0
  Caption = 'DemoMain'
  ClientHeight = 561
  ClientWidth = 919
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
        Left = 339
        Top = 1
        Width = 134
        Height = 70
        Align = alRight
        Caption = 'Alpha-Channel Options'
        ItemIndex = 2
        Items.Strings = (
          'Add Alpha-Channel'
          'Set Opaque'
          'Leave Original Alpha')
        TabOrder = 1
        OnClick = AlphaChannelClick
      end
      object GroupBox4: TGroupBox
        Left = 153
        Top = 1
        Width = 186
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
        Left = 144
        Top = 16
        Width = 314
        Height = 13
        Caption = 'Hold down the mouse over an image to see the alpha-channel'
      end
      object ShowAlpha: TCheckBox
        Left = 12
        Top = 16
        Width = 113
        Height = 17
        Caption = 'Display with Alpha'
        TabOrder = 0
        OnClick = ShowAlphaClick
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
        Top = 0
        Width = 105
        Height = 105
        AutoSize = True
        OnMouseDown = Image1MouseDown
        OnMouseUp = Image1MouseUp
      end
    end
  end
  object Panel2: TPanel
    Left = 480
    Top = 0
    Width = 439
    Height = 561
    Align = alClient
    TabOrder = 1
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 437
      Height = 72
      Align = alTop
      TabOrder = 0
      object GroupBox2: TGroupBox
        Left = 1
        Top = 1
        Width = 200
        Height = 70
        Align = alLeft
        Caption = 'New Size'
        TabOrder = 0
        object Label2: TLabel
          Left = 60
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
          Width = 57
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
          Width = 57
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
          Width = 97
          Height = 17
          Caption = 'Keep Aspect'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object Resize: TButton
          Left = 138
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
        Left = 314
        Top = 1
        Width = 122
        Height = 70
        Align = alRight
        Caption = 'Alpha Combine-Mode'
        ItemIndex = 2
        Items.Strings = (
          'Independent'
          'Pre-Multiplied'
          'Ignore Alpha')
        TabOrder = 1
        OnClick = x
      end
      object GroupBox3: TGroupBox
        Left = 201
        Top = 1
        Width = 113
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
          OnChange = x
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
          OnChange = x
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
      Width = 437
      Height = 487
      Align = alClient
      Caption = 'Panel7'
      TabOrder = 1
      object Splitter2: TSplitter
        Left = 1
        Top = 233
        Width = 435
        Height = 3
        Cursor = crVSplit
        Align = alTop
        ExplicitTop = 42
        ExplicitWidth = 283
      end
      object Panel8: TPanel
        Left = 1
        Top = 1
        Width = 435
        Height = 232
        Align = alTop
        Caption = 'Panel8'
        TabOrder = 0
        object ScrollBox2: TScrollBox
          Left = 1
          Top = 1
          Width = 433
          Height = 191
          HorzScrollBar.Tracking = True
          VertScrollBar.Tracking = True
          Align = alClient
          Color = 3417354
          ParentColor = False
          TabOrder = 0
          OnClick = x
          OnMouseWheel = ScrollBox1MouseWheel
          ExplicitLeft = 0
          ExplicitTop = 4
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
          Width = 433
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
          object ShowAlphaTarget: TCheckBox
            Left = 304
            Top = 0
            Width = 121
            Height = 17
            Caption = 'Display with Alpha'
            TabOrder = 0
            OnClick = ShowAlphaTargetClick
          end
          object RadiusPercent: TSpinEdit
            Left = 152
            Top = 16
            Width = 57
            Height = 22
            MaxValue = 200
            MinValue = 10
            TabOrder = 1
            Value = 100
          end
          object Apply: TButton
            Left = 215
            Top = 16
            Width = 50
            Height = 21
            Caption = 'Apply'
            TabOrder = 2
            OnClick = ApplyClick
          end
        end
      end
      object Panel9: TPanel
        Left = 1
        Top = 236
        Width = 435
        Height = 250
        Align = alClient
        Caption = 'Panel9'
        TabOrder = 1
        object ScrollBox3: TScrollBox
          Left = 1
          Top = 1
          Width = 433
          Height = 209
          HorzScrollBar.Tracking = True
          VertScrollBar.Tracking = True
          Align = alClient
          Color = 3417354
          ParentColor = False
          TabOrder = 0
          OnClick = x
          OnMouseWheel = ScrollBox1MouseWheel
          object Image3: TImage
            Left = 1
            Top = -1
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
          Width = 433
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
            Width = 296
            Height = 13
            Caption = 'Independent resampling and threading are not supported.'
          end
          object ShowAlphaWIC: TCheckBox
            Left = 304
            Top = 0
            Width = 121
            Height = 17
            Caption = 'Display with Alpha'
            TabOrder = 0
            OnClick = ShowAlphaWICClick
          end
        end
      end
    end
  end
  object OPD: TOpenPictureDialog
    Left = 137
    Top = 105
  end
end
