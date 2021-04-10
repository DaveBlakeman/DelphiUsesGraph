object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'Uses Analyser'
  ClientHeight = 563
  ClientWidth = 842
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 842
    Height = 563
    ActivePage = TabSheetJSON
    Align = alClient
    TabOrder = 0
    OnChange = PageControl1Change
    object TabSheetSettings: TTabSheet
      Caption = 'Project Settings'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object PanelDPIFudge: TPanel
        Left = 0
        Top = 0
        Width = 834
        Height = 535
        Align = alClient
        TabOrder = 0
        DesignSize = (
          834
          535)
        object Label1: TLabel
          Left = 3
          Top = 64
          Width = 42
          Height = 13
          Caption = 'Root File'
        end
        object GroupBox1: TGroupBox
          Left = 3
          Top = 96
          Width = 823
          Height = 398
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = 'Search Paths'
          TabOrder = 0
          DesignSize = (
            823
            398)
          object ButtonAddSearchPath: TButton
            Left = 750
            Top = 24
            Width = 70
            Height = 25
            Anchors = [akRight, akBottom]
            Caption = 'Add...'
            TabOrder = 0
            OnClick = ButtonAddSearchPathClick
          end
          object ListBoxSearchPaths: TListBox
            Left = 15
            Top = 24
            Width = 729
            Height = 353
            Anchors = [akLeft, akTop, akRight, akBottom]
            ItemHeight = 13
            TabOrder = 1
            OnClick = ListBoxSearchPathsClick
          end
          object ButtonRemoveSearchPath: TButton
            Left = 748
            Top = 64
            Width = 70
            Height = 25
            Anchors = [akRight, akBottom]
            Caption = 'Remove'
            TabOrder = 2
            OnClick = ButtonRemoveSearchPathClick
          end
        end
        object EditRoot: TEdit
          Left = 72
          Top = 61
          Width = 673
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          OnChange = EditRootChange
        end
        object ButtonBrowseRoot: TButton
          Left = 751
          Top = 59
          Width = 70
          Height = 25
          Anchors = [akTop, akRight]
          Caption = '...'
          TabOrder = 2
          OnClick = ButtonBrowseRootClick
        end
        object ButtonAnalyse: TButton
          Left = 3
          Top = 500
          Width = 134
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Analyse Root File'
          TabOrder = 3
          OnClick = ButtonAnalyseClick
        end
        object Panel2: TPanel
          Left = 1
          Top = 1
          Width = 832
          Height = 35
          Align = alTop
          Caption = 'Project Settings'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 4
          VerticalAlignment = taAlignTop
        end
      end
    end
    object TabSheetStatistics: TTabSheet
      Caption = 'Statistics'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object PanelDPIFudgeStats: TPanel
        Left = 0
        Top = 0
        Width = 834
        Height = 535
        Align = alClient
        TabOrder = 0
        object Splitter1: TSplitter
          Left = 1
          Top = 434
          Width = 832
          Height = 3
          Cursor = crVSplit
          Align = alBottom
          ExplicitLeft = 0
          ExplicitTop = 433
        end
        object StringGridStats: TStringGrid
          Left = 1
          Top = 36
          Width = 832
          Height = 398
          Align = alClient
          DefaultDrawing = False
          FixedCols = 0
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goThumbTracking]
          TabOrder = 0
          OnDrawCell = StringGridStatsDrawCell
          OnMouseDown = StringGridStatsMouseDown
          OnSelectCell = StringGridStatsSelectCell
        end
        object PanelStatsTop: TPanel
          Left = 1
          Top = 1
          Width = 832
          Height = 35
          Align = alTop
          Caption = 'Statistical Analysis of units found'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          VerticalAlignment = taAlignTop
          object LabelStats: TLabel
            Left = 160
            Top = 16
            Width = 71
            Height = 13
            Caption = 'Showing 0 files'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentFont = False
          end
          object CheckBoxShowExternalUnits: TCheckBox
            Left = 0
            Top = 12
            Width = 177
            Height = 17
            Caption = 'Show External Units'
            TabOrder = 0
            OnClick = CheckBoxShowExternalUnitsClick
          end
        end
        object ListBoxUnits: TListBox
          Left = 1
          Top = 437
          Width = 832
          Height = 97
          Align = alBottom
          ItemHeight = 13
          TabOrder = 2
        end
      end
    end
    object TabSheetClasses: TTabSheet
      Caption = 'Classes'
      ImageIndex = 6
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Splitter2: TSplitter
        Left = 0
        Top = 435
        Width = 834
        Height = 3
        Cursor = crVSplit
        Align = alBottom
        ExplicitTop = 429
      end
      object PanelClasses: TPanel
        Left = 0
        Top = 0
        Width = 834
        Height = 35
        Align = alTop
        Caption = 'Statistical Analysis of classes found'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        VerticalAlignment = taAlignTop
        ExplicitTop = 8
        object LabelClasses: TLabel
          Left = 160
          Top = 16
          Width = 71
          Height = 13
          Caption = 'Showing 0 files'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
      end
      object StringGridClasses: TStringGrid
        Left = 0
        Top = 35
        Width = 834
        Height = 400
        Align = alClient
        DefaultDrawing = False
        FixedCols = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goThumbTracking]
        TabOrder = 1
        OnDrawCell = StringGridClassesDrawCell
        OnMouseDown = StringGridClassesMouseDown
        OnSelectCell = StringGridClassesSelectCell
        ExplicitLeft = 1
        ExplicitTop = 36
        ExplicitWidth = 832
        ExplicitHeight = 365
      end
      object ListBoxClassDetails: TListBox
        Left = 0
        Top = 438
        Width = 834
        Height = 97
        Align = alBottom
        ItemHeight = 13
        TabOrder = 2
      end
    end
    object TabSheetGEXF: TTabSheet
      Caption = 'GEXF'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object PanelFudgeGEXF: TPanel
        Left = 0
        Top = 0
        Width = 834
        Height = 535
        Align = alClient
        TabOrder = 0
        object MemoGEXF: TMemo
          Left = 1
          Top = 42
          Width = 832
          Height = 492
          Align = alClient
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object PanelGexfTop: TPanel
          Left = 1
          Top = 1
          Width = 832
          Height = 41
          Align = alTop
          Caption = 'Export Data to GEXF for Gephi graph analysis'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          VerticalAlignment = taAlignTop
          object CheckBoxGexfIntfUses: TCheckBox
            Left = 9
            Top = 18
            Width = 137
            Height = 17
            Caption = 'Export InterfaceUses'
            Checked = True
            State = cbChecked
            TabOrder = 0
            OnClick = CheckBoxGexfIntfUsesClick
          end
          object CheckBoxGexfImplUses: TCheckBox
            Left = 152
            Top = 18
            Width = 166
            Height = 17
            Caption = 'Export Implementation Uses'
            TabOrder = 1
            OnClick = CheckBoxGexfImplUsesClick
          end
        end
      end
    end
    object TabSheetIgnoredFiles: TTabSheet
      Caption = 'Ignored Files'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object PanelFudgeIgnore: TPanel
        Left = 0
        Top = 0
        Width = 834
        Height = 535
        Align = alClient
        TabOrder = 0
        object Panel1: TPanel
          Left = 1
          Top = 1
          Width = 832
          Height = 41
          Align = alTop
          Caption = 
            'Units used but their source can'#39't be found, so ignored from the ' +
            'analysis'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          VerticalAlignment = taAlignTop
        end
        object MemoIgnoredFiles: TMemo
          Left = 1
          Top = 42
          Width = 832
          Height = 492
          Align = alClient
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
    end
    object TabSheetLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object MemoLog: TMemo
        Left = 0
        Top = 0
        Width = 834
        Height = 535
        Align = alClient
        Lines.Strings = (
          '')
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheetJSON: TTabSheet
      Caption = 'JSON'
      ImageIndex = 5
      object PanelJSONExport: TPanel
        Left = 0
        Top = 0
        Width = 834
        Height = 41
        Align = alTop
        Caption = 'Export Data to JSON for GraohCommons graph analysis'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        VerticalAlignment = taAlignTop
        object CheckBoxJSONInterfaceUses: TCheckBox
          Left = 9
          Top = 18
          Width = 137
          Height = 17
          Caption = 'Export InterfaceUses'
          Checked = True
          State = cbChecked
          TabOrder = 0
          OnClick = CheckBoxGexfIntfUsesClick
        end
        object CheckBoxJSONImplementationUses: TCheckBox
          Left = 152
          Top = 18
          Width = 166
          Height = 17
          Caption = 'Export Implementation Uses'
          TabOrder = 1
          OnClick = CheckBoxGexfImplUsesClick
        end
      end
      object MemoJSON: TMemo
        Left = 0
        Top = 41
        Width = 834
        Height = 494
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
  end
  object DirectoryListBox1: TDirectoryListBox
    Left = 632
    Top = 160
    Width = 1
    Height = 25
    TabOrder = 1
  end
  object OpenDialogRoot: TOpenDialog
    Filter = 'Dephi files|*.pas|Delphi projects|*.dpr|Delphi LIbrarie|*.dpk'
    Left = 528
    Top = 136
  end
  object MainMenu1: TMainMenu
    Left = 32
    Top = 24
    object File1: TMenuItem
      Caption = 'File'
      object Open1: TMenuItem
        Caption = 'Open Project...'
        OnClick = Open1Click
      end
      object SaveProject1: TMenuItem
        Caption = 'Save Project...'
        OnClick = SaveProject1Click
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
        OnClick = Exit1Click
      end
    end
  end
  object OpenDialogProject: TOpenDialog
    Filter = 'Usage Analysis  files|*.uaf'
    Left = 616
    Top = 136
  end
  object SaveDialogProject: TSaveDialog
    DefaultExt = '.uaf'
    Filter = 'Usage Analysis  files|*.uaf'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 416
    Top = 296
  end
end
