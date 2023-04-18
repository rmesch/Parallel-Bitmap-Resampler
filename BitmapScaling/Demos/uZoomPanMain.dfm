object ZoomPanMain: TZoomPanMain
  Left = 0
  Top = 0
  Caption = 'ZoomPanMain'
  ClientHeight = 414
  ClientWidth = 874
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI Semibold'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 359
    Top = 0
    Height = 414
    ExplicitLeft = 264
    ExplicitTop = -1
    ExplicitHeight = 339
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 359
    Height = 414
    Align = alLeft
    Caption = 'Panel1'
    TabOrder = 0
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 357
      Height = 56
      Align = alTop
      TabOrder = 0
      object GroupBox1: TGroupBox
        Left = 1
        Top = 1
        Width = 120
        Height = 54
        Align = alLeft
        Caption = 'Test Bitmap'
        TabOrder = 0
        object Make: TButton
          Left = 16
          Top = 16
          Width = 75
          Height = 21
          Caption = 'Make'
          TabOrder = 0
          OnClick = MakeClick
        end
      end
      object GroupBox2: TGroupBox
        Left = 121
        Top = 1
        Width = 235
        Height = 54
        Align = alClient
        Caption = 'Image from File'
        TabOrder = 1
        object Load: TButton
          Left = 16
          Top = 16
          Width = 75
          Height = 21
          Caption = 'Load'
          TabOrder = 0
          OnClick = LoadClick
        end
      end
    end
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 57
      Width = 357
      Height = 330
      HorzScrollBar.Tracking = True
      VertScrollBar.Tracking = True
      Align = alClient
      TabOrder = 1
      object Image1: TImage
        Left = 0
        Top = 0
        Width = 105
        Height = 105
        AutoSize = True
      end
    end
    object Panel6: TPanel
      Left = 1
      Top = 387
      Width = 357
      Height = 26
      Align = alBottom
      Caption = 
        'The test bitmap is very unforgiving when animated, try a real pi' +
        'cture.'
      TabOrder = 2
    end
  end
  object Panel2: TPanel
    Left = 362
    Top = 0
    Width = 512
    Height = 414
    Align = alClient
    ParentBackground = False
    TabOrder = 1
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 510
      Height = 56
      Align = alTop
      TabOrder = 0
      object GroupBox3: TGroupBox
        Left = 1
        Top = 1
        Width = 508
        Height = 54
        Align = alClient
        Caption = 'Animation'
        TabOrder = 0
        ExplicitTop = -4
        object Label1: TLabel
          Left = 3
          Top = 12
          Width = 37
          Height = 13
          Caption = 'Height:'
        end
        object Label2: TLabel
          Left = 111
          Top = 12
          Width = 55
          Height = 13
          Caption = 'Time [sec]:'
        end
        object Label3: TLabel
          Left = 175
          Top = 12
          Width = 29
          Height = 13
          Caption = 'Filter:'
        end
        object Label4: TLabel
          Left = 263
          Top = 12
          Width = 111
          Height = 13
          Caption = 'Radius [% of Default]:'
        end
        object Heights: TComboBox
          Left = 3
          Top = 28
          Width = 102
          Height = 21
          Style = csDropDownList
          TabOrder = 0
          OnChange = HeightsChange
        end
        object Time: TSpinEdit
          Left = 111
          Top = 27
          Width = 58
          Height = 22
          Increment = 5
          MaxValue = 40
          MinValue = 20
          TabOrder = 1
          Value = 20
        end
        object Start: TButton
          Left = 374
          Top = 28
          Width = 75
          Height = 21
          Caption = 'Start'
          TabOrder = 2
          OnClick = StartClick
        end
        object Filter: TComboBox
          Left = 175
          Top = 28
          Width = 82
          Height = 21
          Style = csDropDownList
          ItemIndex = 2
          TabOrder = 3
          Text = 'Bicubic'
          Items.Strings = (
            'Box'
            'Bilinear'
            'Bicubic'
            'Lanczos')
        end
        object RadiusPercent: TSpinEdit
          Left = 263
          Top = 27
          Width = 66
          Height = 22
          MaxValue = 300
          MinValue = 10
          TabOrder = 4
          Value = 100
        end
      end
    end
    object MoviePanel: TPanel
      Left = 1
      Top = 57
      Width = 510
      Height = 330
      Align = alClient
      Color = clBlack
      ParentBackground = False
      TabOrder = 1
      OnResize = MoviePanelResize
      object MovieBox: TPaintBox
        Left = 32
        Top = 32
        Width = 209
        Height = 113
        OnPaint = MovieBoxPaint
      end
    end
    object Panel5: TPanel
      Left = 1
      Top = 387
      Width = 510
      Height = 26
      Align = alBottom
      TabOrder = 2
      object FPS: TLabel
        Left = 16
        Top = 8
        Width = 18
        Height = 13
        Caption = 'FPS'
      end
      object Radius: TLabel
        Left = 56
        Top = 8
        Width = 63
        Height = 13
        Caption = 'Filter-Radius'
      end
      object Label5: TLabel
        Left = 184
        Top = 8
        Width = 294
        Height = 13
        Caption = 'Increasing the radius smoothes the animation, but blurs it.'
      end
    end
  end
  object OPD: TOpenPictureDialog
    Left = 161
    Top = 81
  end
end
