unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.StdCtrls,
  DelphiProject, LexicalAnalyser, Vcl.Grids,
  DelphiUnit,
  DelphiClass,
  Vcl.ComCtrls, Vcl.ExtCtrls, System.UITypes,
  {$WARN SYMBOL_PLATFORM OFF}
  Vcl.FileCtrl
  {$WARN SYMBOL_PLATFORM ON}
  ;

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
    ButtonAddSearchPath: TButton;
    DirectoryListBox1: TDirectoryListBox;
    ListBoxSearchPaths: TListBox;
    ButtonRemoveSearchPath: TButton;
    TabSheetJSON: TTabSheet;
    PanelJSONExport: TPanel;
    CheckBoxJSONInterfaceUses: TCheckBox;
    CheckBoxJSONImplementationUses: TCheckBox;
    MemoJSON: TMemo;
    TabSheetClasses: TTabSheet;
    PanelClasses: TPanel;
    LabelClasses: TLabel;
    StringGridClasses: TStringGrid;
    ListBoxClassDetails: TListBox;
    Splitter2: TSplitter;
    procedure Exit1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonAnalyseClick(Sender: TObject);
    procedure SaveProject1Click(Sender: TObject);
    procedure ButtonBrowseRootClick(Sender: TObject);
    procedure EditRootChange(Sender: TObject);
    procedure CheckBoxShowExternalUnitsClick(Sender: TObject);
    procedure StringGridStatsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure StringGridStatsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure StringGridStatsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PageControl1Change(Sender: TObject);
    procedure CheckBoxGexfIntfUsesClick(Sender: TObject);
    procedure CheckBoxGexfImplUsesClick(Sender: TObject);
    procedure ButtonAddSearchPathClick(Sender: TObject);
    procedure ButtonRemoveSearchPathClick(Sender: TObject);
    procedure ListBoxSearchPathsClick(Sender: TObject);
    procedure StringGridClassesDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure StringGridClassesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGridClassesSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
  private
    fProject: TDelphiProject;
    procedure CheckControls;
    function Confirm(Msg: String): Boolean;
    procedure ParseFile(FileName: String);
    procedure Log(S: String; Level: TLogLevel = llInfo);
    procedure InitStatsGrid;
    procedure InitClassesGrid;
    function  UnitStatTypeForCol(Col: Integer): TDelphiUnitStatType;
    procedure UpdateGexf();
    procedure UpdateIgnoredFiles();
    procedure UpdateJson;
    procedure LoadStatsGrid(SortCol: TDelphiUnitStatType; Ascending: Boolean; ShowExternalUnits: Boolean);
    procedure LoadClassesGrid(SortCol: TDelphiClassStatType; Ascending: Boolean);
    function ClassStatTypeForCol(Col: Integer): TDelphiClassStatType;
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
  GexfExport, JSONExport;

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
  cStatsColIntfClasses    = 9;
  cStatsColIntfProcs      = 10;
  cStatsColIntfDependency = 11;
  cStatsColImplDependency = 12;
  cStatsColCyclic         = 13;
  cStatsColFileName       = 14;

  cClassesColName         = 0;
  cClassesColProcs        = 1;
  cClassesColProperties   = 2;
  cClassesColUnits        = 3;
  cClassesColFileName     = 4;

procedure TFormMain.ButtonAddSearchPathClick(Sender: TObject);
begin
  {$WARN SYMBOL_PLATFORM OFF}
  with TFileOpenDialog.Create(nil) do
    try
      Options := [fdoPickFolders];
      if Execute then
      begin
        ListBoxSearchPaths.AddItem(FileName, nil);
        fProject.Settings.SearchDirs.Add(FileName);
        CheckControls
      end;
    finally
      Free;
    end;
  {$WARN SYMBOL_PLATFORM ON}
end;

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

procedure TFormMain.ButtonRemoveSearchPathClick(Sender: TObject);
var
 Selected: String;
 Index   : Integer;
begin
  if (ListBoxSearchPaths.ItemIndex <> -1) then
  begin
    Selected:=ListBoxSearchPaths.Items[ListBoxSearchPaths.ItemIndex];
    if Confirm('Remove "' + Selected + '" ?') then
    begin
      ListBoxSearchPaths.DeleteSelected;
      CheckControls;
      Index:=fProject.Settings.SearchDirs.IndexOf(Selected);
      if Index <> -1 then
        fProject.Settings.SearchDirs.Delete(Index);
    end
  end;
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
  LoadStatsGrid(duName, True, CheckBoxShowExternalUnits.Checked);
end;

procedure TFormMain.CheckControls;
begin
  ButtonRemoveSearchPath.Enabled:=ListBoxSearchPaths.ItemIndex <> -1
end;

function TFormMain.Confirm(Msg: String): Boolean;
begin
  Result:=MessageDlg(Msg, mtConfirmation, [mbOK, mbCancel], 0) = mrOk
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
  InitStatsGrid;
  InitClassesGrid;
  PageControl1.TabIndex:=0;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fProject)
end;

procedure TFormMain.InitStatsGrid;

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
  AddHeading( cStatsColIntfClasses, 'Intf Classes', 100);
  AddHeading( cStatsColIntfProcs, 'Intf Routines', 100);
  AddHeading( cStatsColIntfDependency, 'Intf Dependency', 100);
  AddHeading( cStatsColImplDependency, 'Impl Dependency', 100);
  AddHeading( cStatsColCyclic,     'Cyclic', 100);
  AddHeading( cStatsColFileName,  'File Name', 500);
  StringGridStats.ColCount:=LastColIndex+1
end;

procedure TFormMain.InitClassesGrid;

  var
    LastColIndex: Integer;

  procedure AddHeading(Col: Integer; Title: String; Width: Integer);
  begin
    StringGridClasses.Cells    [Col, 0] := Title;
    StringGridClasses.ColWidths[Col   ] := width;
    StringGridClasses.Objects  [Col, 0] := TObject(False); // last sort order
    LastColIndex:=Max(LastColIndex, Col);
  end;

begin
  LastColIndex:=0;
  StringGridClasses.ColCount:=100;
  AddHeading( cClassesColName,        'Unit', 300);
  AddHeading( cClassesColProcs,       'Routines', 100);
  AddHeading( cClassesColProperties,  'Properties', 100);
  AddHeading( cClassesColUnits,       'Units', 100);
  AddHeading( cClassesColFileName,    'File Name', 500);

  StringGridClasses.ColCount:=LastColIndex+1
end;

procedure TFormMain.ListBoxSearchPathsClick(Sender: TObject);
begin
  CheckControls
end;

procedure TFormMain.LoadStatsGrid(SortCol: TDelphiUnitStatType; Ascending: Boolean; ShowExternalUnits: Boolean);

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
    StringGridStats.Cells[cStatsColIntfClasses,Row]     := IntToStr(U.InterfaceClasses.Count);
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

procedure TFormMain.LoadClassesGrid(SortCol: TDelphiClassStatType; Ascending: Boolean);

  procedure AddRow(C: TDelphiClass; Row: Integer);
  begin
    StringGridClasses.Objects[0, Row]                     := C;
    StringGridClasses.Cells[cClassesColName      ,   Row] := C.Name;
    StringGridClasses.Cells[cClassesColProcs     ,   Row] := IntToStr(C.Routines.Count);
    StringGridClasses.Cells[cClassesColProperties,   Row] := IntToStr(C.Properties.Count);
    StringGridClasses.Cells[cClassesColUnits     ,   Row] := IntToStr(C.UnitsReferencing.Count);
    StringGridClasses.Cells[cClassesColFileName  ,   Row] := C.FileName;
  end;

var
  Classes: TObjectList<TDelphiClass>;
  C: TDelphiClass;
  Row: Integer;
begin
  Classes:=TObjectList<TDelphiClass>.Create(False);
  try
    fProject.GetClassesSorted(SortCol, Ascending, Classes);
    LabelClasses.Caption:='Showing ' + IntToStr(Classes.Count) + ' classes';
    StringGridClasses.RowCount:=1+Classes.Count;
    Row:=1;
    for C in Classes do
    begin
      AddRow(C, Row);
      Inc(Row)
    end;
  finally
    FreeAndnil(Classes);
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

procedure TFormMain.Open1Click(Sender: TObject);
begin
  if OpenDialogProject.Execute then
  begin
    fProject.LoadFromFile(OpenDialogProject.FileName);
    EditRoot.Text:=fProject.Settings.RootFileName;
    ListBoxSearchPaths.Items.Assign(fProject.Settings.SearchDirs);
    CheckControls;
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

procedure TFormMain.UpdateJson();
var
  Exporter: TJSONExport;
  Options : TJSONExportOptions;
begin
  Options:=[];
  if CheckBoxJSONInterfaceUses.Checked then
    Options:=Options + [JSONExportIntfUses];
  if CheckBoxJSONImplementationUses.Checked then
    Options:=Options + [JSONExportImplUses];
  Exporter:=TJSONExport.Create;
  try
    Exporter.ExportProjectToStrings(fProject, MemoJSON.Lines, Options);
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
  else if PageControl1.ActivePage = TabSheetJSON then
    UpdateJSON()
  else if PageControl1.ActivePage = TabSheetIgnoredFiles then
    UpdateIgnoredFiles()
end;

procedure TFormMain.ParseFile(FileName: String);
begin
  fProject.Parse(FileName, Log);
  if Confirm('Analyse classes? This may take several minutes?') then
    fProject.AnalyseClassReferences;
  Log('');
  Log('Done.');
  MemoLog.SelStart:=Length(MemoLog.Text);
  LoadStatsGrid(duName, True, CheckBoxShowExternalUnits.Checked);
  LoadClassesGrid(dcName, True);
  //fProject.UnParse(MemoLog.Lines);
end;

procedure TFormMain.SaveProject1Click(Sender: TObject);
begin
  if SaveDialogProject.Execute then
    fProject.SaveToFile(SaveDialogProject.FileName);
end;

function TFormMain.UnitStatTypeForCol(Col: Integer): TDelphiUnitStatType;
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
    cStatsColIntfClasses    : Result:= duClasses;
    cStatsColIntfProcs      : Result:= duRoutines;
    cStatsColFileName       : Result:= duFileName;
    cStatsColIntfDependency : Result:= duIntfDependency;
    cStatsColImplDependency : Result:= duImplDependency;
    cStatsColCyclic         : Result:= duCyclic
  else
    raise Exception.Create('UnitStatTypeForCol: unknown column');
  end
end;

function TFormMain.ClassStatTypeForCol(Col: Integer): TDelphiClassStatType;
begin
  case col of
    cClassesColName           : Result:= dcName;
    cClassesColProcs          : Result:= dcRoutines;
    cClassesColProperties     : Result:= dcProperties;
    cClassesColUnits          : Result:= dcUnitsReferencing;
    cClassesColFileName       : Result:= dcFileName;
  else
    raise Exception.Create('ClassStatTypeForCol: unknown column');
  end
end;

procedure TFormMain.StringGridClassesDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
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


procedure TFormMain.StringGridClassesMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

  function ColWasAscending(Col: Integer): Boolean;
  begin
    Result:= Boolean(StringGridClasses.Objects  [Col, 0])
  end;

  procedure  SetColSortOrder(Col: Integer; Ascending: Boolean);
  begin
    StringGridClasses.Objects  [Col, 0] := TObject(Ascending);
  end;

  procedure SortGrid(Col: Integer);
  var
    WasAscending: Boolean;
  begin
    WasAscending:=ColWasAscending(Col);
    LoadClassesGrid(ClassStatTypeForCol(Col), not WasAscending);
    SetColSortOrder(Col, not WasAscending);
  end;

var
  ACol, ARow: Integer;
begin
  StringGridClasses.MouseToCell(X, Y, ACol, ARow);
  if (ARow = 0) then
  begin
    SortGrid(ACol);
    //ListBoxUnits.Clear;
  end
end;

procedure TFormMain.StringGridClassesSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);

var
  SelectedClass: TDelphiClass;
  StatType: TDelphiClassStatType;
begin
  if (ARow > 0) then
  begin
    if StringGridClasses.Objects[0, ARow] is TDelphiClass then
    begin
      StatType:=ClassStatTypeForCol(ACol);
      SelectedClass:=StringGridClasses.Objects[0, ARow] as TDelphiClass;
      SelectedClass.GetStatDetails(StatType, ListBoxClassDetails.Items);
    end
    else
      ListBoxClassDetails.Clear;
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
    LoadStatsGrid(UnitStatTypeForCol(Col), not WasAscending, CheckBoxShowExternalUnits.Checked);
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
      SelectedUnit.GetStatDetails(UnitStatTypeForCol(ACol), ListBoxUnits.Items);
    end
    else
      ListBoxUnits.Clear;
  end
end;

end.
