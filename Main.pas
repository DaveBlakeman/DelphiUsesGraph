unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.StdCtrls,
  DelphiProject, LexicalAnalyser, Vcl.Grids,
  DelphiUnit, Vcl.ComCtrls, Vcl.ExtCtrls, System.UITypes;

type
  TFormMain = class(TForm)
    OpenDialogRoot: TOpenDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    Exit1: TMenuItem;
    OpenDialogProject: TOpenDialog;
    SaveDialogProject: TSaveDialog;
    SaveProject1: TMenuItem;
    PageControl1: TPageControl;
    TabSheetSettings: TTabSheet;
    TabSheetLog: TTabSheet;
    TabSheetStatistics: TTabSheet;
    MemoLog: TMemo;
    PanelDPIFudge: TPanel;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    MemoSearchPaths: TMemo;
    EditRoot: TEdit;
    ButtonBrowseRoot: TButton;
    ButtonAnalyse: TButton;
    PanelDPIFudgeStats: TPanel;
    StringGridStats: TStringGrid;
    PanelStatsTop: TPanel;
    CheckBoxShowExternalUnits: TCheckBox;
    LabelStats: TLabel;
    Splitter1: TSplitter;
    ListBoxUnits: TListBox;
    TabSheetGEXF: TTabSheet;
    PanelFudgeGEXF: TPanel;
    MemoGEXF: TMemo;
    PanelGexfTop: TPanel;
    CheckBoxGexfIntfUses: TCheckBox;
    CheckBoxGexfImplUses: TCheckBox;
    TabSheetIgnoredFiles: TTabSheet;
    PanelFudgeIgnore: TPanel;
    Panel1: TPanel;
    MemoIgnoredFiles: TMemo;
    Panel2: TPanel;
    procedure Exit1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonAnalyseClick(Sender: TObject);
    procedure SaveProject1Click(Sender: TObject);
    procedure ButtonBrowseRootClick(Sender: TObject);
    procedure EditRootChange(Sender: TObject);
    procedure MemoSearchPathsChange(Sender: TObject);
    procedure CheckBoxShowExternalUnitsClick(Sender: TObject);
    procedure StringGridStatsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure StringGridStatsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure StringGridStatsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PageControl1Change(Sender: TObject);
    procedure CheckBoxGexfIntfUsesClick(Sender: TObject);
    procedure CheckBoxGexfImplUsesClick(Sender: TObject);
  private
    fProject: TDelphiProject;
    procedure ParseFile(FileName: String);
    procedure Log(S: String; Level: TLogLevel = llInfo);
    procedure LoadGrid(SortCol: TDelphiUnitStatType; Ascending: Boolean; ShowExternalUnits: Boolean);
    procedure InitGrid;
    function StatTypeForCol(Col: Integer): TDelphiUnitStatType;
    procedure UpdateGexf();
    procedure UpdateIgnoredFiles();
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  System.Generics.Collections,
  System.Math,
  GexfExport;

const
  cStatsColName           = 0;
  cStatsColIntfUses       = 1;
  cStatsColImplUses       = 2;
  cStatsColIntfRefs       = 3;
  cStatsColImplRefs       = 4;
  cStatsColLineCount      = 5;
  cStatsColWeighting      = 6;
  cStatsColDepth          = 7;
  cStatsColDepthDiff      = 8;
  cStatsColIntfProcs      = 9;
  cStatsColIntfDependency = 10;
  cStatsColImplDependency = 11;
  cStatsColCyclic         = 12;
  cStatsColFileName       = 13;

procedure TFormMain.ButtonAnalyseClick(Sender: TObject);
begin
  MemoLog.Lines.BeginUpdate;
  try
    PageControl1.ActivePage:=TabSheetLog;
    ParseFile(EditRoot.Text);
    PageControl1.ActivePage:=TabSheetStatistics;
  finally
    MemoLog.Lines.EndUpdate
  end;
end;

procedure TFormMain.ButtonBrowseRootClick(Sender: TObject);
begin
  if OpenDialogRoot.Execute then
     EditRoot.Text:=OpenDialogRoot.FileName
end;

procedure TFormMain.CheckBoxGexfImplUsesClick(Sender: TObject);
begin
  UpdateGexf
end;

procedure TFormMain.CheckBoxGexfIntfUsesClick(Sender: TObject);
begin
  UpdateGexf;
end;

procedure TFormMain.CheckBoxShowExternalUnitsClick(Sender: TObject);
begin
  LoadGrid(duName, True, CheckBoxShowExternalUnits.Checked);
end;

procedure TFormMain.EditRootChange(Sender: TObject);
begin
  fProject.Settings.RootFileName:=EditRoot.Text;
end;

procedure TFormMain.Exit1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  fProject:=TDelphiProject.Create;
  InitGrid;
  PageControl1.TabIndex:=0;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fProject)
end;

procedure TFormMain.InitGrid;

  var
    LastColIndex: Integer;

  procedure AddHeading(Col: Integer; Title: String; Width: Integer);
  begin
    StringGridStats.Cells    [Col, 0] := Title;
    StringGridStats.ColWidths[Col   ] := width;
    StringGridStats.Objects  [Col, 0] := TObject(False); // last sort order
    LastColIndex:=Max(LastColIndex, Col);
  end;

begin
  LastColIndex:=0;
  StringGridStats.ColCount:=100;
  AddHeading( cStatsColName,      'Unit', 300);
  AddHeading( cStatsColIntfUses,  'Int Uses', 100);
  AddHeading( cStatsColImplUses,  'Impl Uses', 100);
  AddHeading( cStatsColIntfRefs,  'Refs from Intf', 100);
  AddHeading( cStatsColImplRefs,  'Refs from Impl', 100);
  AddHeading( cStatsColLineCount, 'Lines', 100);
  AddHeading( cStatsColWeighting, 'Weighting', 100);
  AddHeading( cStatsColDepth,     'Depth', 100);
  AddHeading( cStatsColDepthDiff, 'Depth Diff', 100);
  AddHeading( cStatsColIntfProcs, 'Intf Routines', 100);
  AddHeading( cStatsColIntfDependency, 'Intf Dependency', 100);
  AddHeading( cStatsColImplDependency, 'Impl Dependency', 100);
  AddHeading( cStatsColCyclic,     'Cyclic', 100);
  AddHeading( cStatsColFileName,  'File Name', 500);
  StringGridStats.ColCount:=LastColIndex+1
end;

procedure TFormMain.LoadGrid(SortCol: TDelphiUnitStatType; Ascending: Boolean; ShowExternalUnits: Boolean);

  procedure AddRow(U: TDelphiUnit; Row: Integer);
  begin
    StringGridStats.Objects[0, Row]                     := U;
    StringGridStats.Cells[cStatsColName    ,   Row]     := U.Name;
    StringGridStats.Cells[cStatsColIntfUses,   Row]     := IntToStr(U.InterfaceUses.Count);
    StringGridStats.Cells[cStatsColImplUses,   Row]     := IntToStr(U.ImplementationUses.Count);
    StringGridStats.Cells[cStatsColIntfRefs,   Row]     := IntToStr(U.RefsFromInterfaces.Count);
    StringGridStats.Cells[cStatsColImplRefs,   Row]     := IntToStr(U.RefsFromImplementations.Count);
    StringGridStats.Cells[cStatsColLineCount,  Row]     := IntToStr(U.LineCount);
    StringGridStats.Cells[cStatsColWeighting,  Row]     := IntToStr(U.Weighting);
    StringGridStats.Cells[cStatsColDepth    ,  Row]     := IntToStr(U.Depth);
    StringGridStats.Cells[cStatsColDepthDiff,  Row]     := IntToStr(U.DepthDifferential);
    StringGridStats.Cells[cStatsColIntfProcs,  Row]     := IntToStr(U.InterfaceRoutines.Count);
    StringGridStats.Cells[cStatsColIntfDependency, Row] := IntToStr(U.MaxInterfaceDependency);
    StringGridStats.Cells[cStatsColImplDependency, Row] := IntToStr(U.MaxDependency);
    StringGridStats.Cells[cStatsColCyclic,     Row]     := BoolToStr(U.ContainsCycles, True);
    StringGridStats.Cells[cStatsColFileName,   Row]     := U.FileName;
  end;

var
  Units: TObjectList<TDelphiUnit>;
  U: TDelphiUnit;
  Row: Integer;
begin
  Units:=TObjectList<TDelphiUnit>.Create(False);
  try
    fProject.GetUnitsSorted(SortCol, Ascending, ShowExternalUnits, Units);
    LabelStats.Caption:='Showing ' + IntToStr(Units.Count) + ' units';
    StringGridStats.RowCount:=1+Units.Count;
    Row:=1;
    for U in Units do
    begin
      AddRow(U, Row);
      Inc(Row)
    end;
  finally
    FreeAndnil(Units);
  end;
end;

procedure TFormMain.Log(S: String; Level: TLogLevel);
begin
  case Level of
    llInfo   : MemoLog.Lines.Add(s);
    llWarning: MemoLog.Lines.Add('Warning: ' + s);
    llError  : MemoLog.Lines.Add('ERROR: ' + s);
  end;
end;

procedure TFormMain.MemoSearchPathsChange(Sender: TObject);
begin
  fProject.Settings.SearchDirs.Assign(MemoSearchPaths.Lines);
end;

procedure TFormMain.Open1Click(Sender: TObject);
begin
  if OpenDialogProject.Execute then
  begin
    fProject.LoadFromFile(OpenDialogProject.FileName);
    EditRoot.Text:=fProject.Settings.RootFileName;
    MemoSearchPaths.Text:=fProject.Settings.SearchDirs.Text;
  end;
end;

procedure TFormMain.UpdateGexf();
var
  Exporter: TGexfExport;
  Options: TGexfExportOptions;
begin
  Options:=[];
  if CheckBoxGexfIntfUses.Checked then
    Options:=Options + [gexfExportIntfUses];
  if CheckBoxGexfImplUses.Checked then
    Options:=Options + [gexfExportImplUses];
  Exporter:=TGexfExport.Create;
  try
    Exporter.ExportProjectToStrings(fProject, MemoGEXF.Lines, Options);
  finally
    FreeAndNil(Exporter);
  end;
end;

procedure TFormMain.UpdateIgnoredFiles;
begin
  fProject.GetIgnoredFiles(MemoIgnoredFiles.Lines)
end;

procedure TFormMain.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePage = TabSheetGEXF then
    UpdateGexf()
  else if PageControl1.ActivePage = TabSheetIgnoredFiles then
    UpdateIgnoredFiles()
end;

procedure TFormMain.ParseFile(FileName: String);
begin
  fProject.Parse(FileName, Log);
  Log('');
  Log('Done.');
  MemoLog.SelStart:=Length(MemoLog.Text);
  LoadGrid(duName, True, CheckBoxShowExternalUnits.Checked);
  //fProject.UnParse(MemoLog.Lines);
end;

procedure TFormMain.SaveProject1Click(Sender: TObject);
begin
  if SaveDialogProject.Execute then
    fProject.SaveToFile(SaveDialogProject.FileName);
end;

function TFormMain.StatTypeForCol(Col: Integer): TDelphiUnitStatType;
begin
  case col of
    cStatsColName           : Result:= duName;
    cStatsColIntfUses       : Result:= duIntfUses;
    cStatsColImplUses       : Result:= duImplUses;
    cStatsColIntfRefs       : Result:= duIntfRefs;
    cStatsColImplRefs       : Result:= duImplRefs;
    cStatsColLineCount      : Result:= duLineCount;
    cStatsColWeighting      : Result:= duWeighting;
    cStatsColDepth          : Result:= duDepth;
    cStatsColDepthDiff      : Result:= duDepthDiff;
    cStatsColIntfProcs      : Result:= duRoutines;
    cStatsColFileName       : Result:= duFileName;
    cStatsColIntfDependency : Result:= duIntfDependency;
    cStatsColImplDependency : Result:= duImplDependency;
    cStatsColCyclic         : Result:= duCyclic
  else
    raise Exception.Create('SortColForCol: unknown column');
  end
end;


procedure TFormMain.StringGridStatsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  SaveBrush: TBrushRecall;
  SaveFont : TFontRecall;
begin
  with Sender as TStringGrid do
  begin
    SaveBrush:=TBrushRecall.Create(Canvas.Brush);
    SaveFont  :=TFontRecall.Create(Canvas.Font);
    try
      if gdFixed in State then
      begin
        Canvas.Brush.Color := clNavy;
        Canvas.Font.Color  := clWhite;
      end;
      Canvas.FillRect(Rect);
      if gdSelected in State then
      begin
        Canvas.Brush.Color := clSkyBlue;
        Canvas.Font.Style:=Canvas.Font.Style + [fsBold];
      end;
      Canvas.TextOut(Rect.Left+2,Rect.Top+2, Cells[ACol, ARow]);
    finally
      FreeAndNil(SaveBrush);
      FreeAndNil(SaveFont);
    end;
  end;
end;

procedure TFormMain.StringGridStatsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

  function ColWasAscending(Col: Integer): Boolean;
  begin
    Result:= Boolean(StringGridStats.Objects  [Col, 0])
  end;

  procedure  SetColSortOrder(Col: Integer; Ascending: Boolean);
  begin
    StringGridStats.Objects  [Col, 0] := TObject(Ascending);
  end;

  procedure SortGrid(Col: Integer);
  var
    WasAscending: Boolean;
  begin
    WasAscending:=ColWasAscending(Col);
    LoadGrid(StatTypeForCol(Col), not WasAscending, CheckBoxShowExternalUnits.Checked);
    SetColSortOrder(Col, not WasAscending);
  end;

var
  ACol, ARow: Integer;
begin
  StringGridStats.MouseToCell(X, Y, ACol, ARow);
  if (ARow = 0) then
  begin
    SortGrid(ACol);
    ListBoxUnits.Clear;
  end
end;

procedure TFormMain.StringGridStatsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  SelectedUnit: TDelphiUnit;
begin
  if (ARow > 0) then
  begin
    if StringGridStats.Objects[0, ARow] is TDelphiUnit then
    begin
      SelectedUnit:=StringGridStats.Objects[0, ARow] as TDelphiUnit;
      SelectedUnit.GetStatDetails(StatTypeForCol(ACol), ListBoxUnits.Items);
    end
    else
      ListBoxUnits.Clear;
  end
end;

end.
