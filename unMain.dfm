object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'FormMain'
  ClientHeight = 438
  ClientWidth = 798
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object splMain: TSplitter
    Left = 235
    Top = 0
    Height = 438
    ExplicitLeft = 24
    ExplicitTop = 24
    ExplicitHeight = 100
  end
  object chtMain: TChart
    Left = 238
    Top = 0
    Width = 560
    Height = 438
    Title.Text.Strings = (
      #1044#1072#1085#1085#1099#1077)
    View3D = False
    Align = alClient
    TabOrder = 0
    DefaultCanvas = 'TGDIPlusCanvas'
    ColorPaletteIndex = 5
  end
  object pnlControl: TPanel
    Left = 0
    Top = 0
    Width = 235
    Height = 438
    Align = alLeft
    TabOrder = 1
    object grpRect: TGroupBox
      Left = 24
      Top = 16
      Width = 185
      Height = 146
      Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099' '#1087#1088#1103#1084#1086#1091#1075#1086#1083#1100#1085#1080#1082#1072
      TabOrder = 0
      object lblX1: TLabel
        Left = 16
        Top = 24
        Width = 16
        Height = 13
        Caption = 'X1:'
      end
      object lblX2: TLabel
        Left = 16
        Top = 81
        Width = 16
        Height = 13
        Caption = 'X2:'
      end
      object lblY1: TLabel
        Left = 16
        Top = 52
        Width = 16
        Height = 13
        Caption = 'Y1:'
      end
      object lblY2: TLabel
        Left = 16
        Top = 108
        Width = 16
        Height = 13
        Caption = 'Y2:'
      end
      object edtX1: TEdit
        Left = 40
        Top = 21
        Width = 121
        Height = 21
        TabOrder = 0
        Text = '-43601'
      end
      object edtX2: TEdit
        Left = 40
        Top = 78
        Width = 121
        Height = 21
        TabOrder = 1
        Text = '-36210'
      end
      object edtY1: TEdit
        Left = 40
        Top = 49
        Width = 121
        Height = 21
        TabOrder = 2
        Text = '-200933'
      end
      object edtY2: TEdit
        Left = 40
        Top = 105
        Width = 121
        Height = 21
        TabOrder = 3
        Text = '-196468'
      end
    end
    object btnCutContours: TButton
      Left = 40
      Top = 264
      Width = 145
      Height = 25
      Caption = #1054#1073#1088#1077#1079#1072#1090#1100
      Enabled = False
      TabOrder = 1
      OnClick = btnCutContoursClick
    end
    object btnSelectDirectory: TButton
      Left = 40
      Top = 192
      Width = 145
      Height = 25
      Caption = #1042#1099#1073#1088#1072#1090#1100' '#1076#1080#1088#1077#1082#1090#1086#1088#1080#1102
      TabOrder = 2
      OnClick = btnSelectDirectoryClick
    end
    object btnSaveContours: TButton
      Left = 40
      Top = 320
      Width = 145
      Height = 25
      Caption = ' '#1057#1086#1093#1088#1072#1085#1080#1090#1100
      Enabled = False
      TabOrder = 3
      OnClick = btnSaveContoursClick
    end
    object chkExcludeReplay: TCheckBox
      Left = 40
      Top = 233
      Width = 145
      Height = 17
      Caption = #1048#1089#1082#1083#1102#1095#1080#1090#1100' '#1087#1086#1074#1090#1086#1088#1099
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
  end
  object flsvdlgMain: TFileSaveDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 176
    Top = 288
  end
end
