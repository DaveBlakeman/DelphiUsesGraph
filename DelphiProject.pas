unit DelphiProject;

interface

uses
  System.Types,
  System.Generics.Collections,
  Classes,
  DelphiUnit,
  LexicalAnalyser,
  ProjectSettings,
  DelphiClass;

type

  TDelphiProject = class
  private
    fLogProc     : TInfoProc;
    fSettings    : TProjectSettings;
    fFileNames   : TDictionary<string, string>;   // map unit name to Filename
    fIgnoredFiles: TDictionary<string, string>;
    fUnits       : TDictionary<string, TDelphiUnit>; (* owns units *)
    fMainUnit    : TDelphiUnit; (* user ref *)

    procedure CollectFileNames(Path: String);

    procedure Log(S: String; Level: TLogLevel = llInfo);

    procedure ParseUnit(U: TDelphiUnit; FileName: String; Depth: Integer);

    procedure ParsedUsedUnits(ReferringUnit: TDelphiUnit; Depth: Integer);

    procedure GetUnitsContainingClass(ClassName: String; Units: TStrings (* name -> Unit *));
  public
    constructor Create;
    destructor Destroy; override;

    procedure Parse(FileName: String; LogProc: TInfoProc);
    procedure UnParse(Strings: TStrings);

    procedure AnalyseClassReferences;

    procedure LoadFromFile(FileName: String);
    procedure SaveToFile(FileName: String);

    procedure GetUnitsSorted(SortCol: TDelphiUnitStatType; Ascending: boolean; IncludeExternalUnits: Boolean; Units: TList<TDelphiUnit>);
    procedure GetClassesSorted(SortCol: TDelphiClassStatType; Ascending: boolean; Classes: TList<TDelphiClass>);


    procedure GetIgnoredFiles(Strings: TStrings);

    property LogProc : TInfoProc read fLogProc;
    property Units   : TDictionary<string, TDelphiUnit> read fUnits;
    property MainUnit: TDelphiUnit                      read FMainUnit write fMainUnit;
    property Settings: TProjectSettings                 read fSettings;
  end;

implementation

uses
  System.Generics.Defaults,
  System.IOUtils,
  SysUtils;

{ TDelphiProject }

procedure TDelphiProject.AnalyseClassReferences;
var
  U: TDelphiUnit;
  C: TDelphiClass;
begin
  Log('Analysing Class Refs...');
  for U in fUnits.Values do
    for C in U.InterfaceClasses do
      GetUnitsContainingClass(C.Name, C.UnitsReferencing);
  Log('Analysed Class Refs');
end;

procedure TDelphiProject.CollectFileNames(Path: String);
var
  FileNames : TStringDynArray;
  FileName  : String;
  UnitName  : String;
begin
  if DirectoryExists(Path) then
  begin
    FileNames:=TDirectory.GetFiles(Path, '*.pas', TSearchOption.soAllDirectories);
    for FileName in FileNames do
    begin
      UnitName:=ExtractFileName(FileName);
      UnitName:=StringReplace(UnitName, '.pas', '', [rfReplaceAll, rfIgnoreCase]);
      if not fFileNames.ContainsKey(UnitName) then
        fFileNames.Add(UnitName, FileName)
      else
        Log('Duplicate unit name found: "' + UnitName + '"', llWarning);
    end;
  end
  else
    Log('Could not find folder "' + Path + '"')

end;

constructor TDelphiProject.Create;
begin
  fSettings:=TProjectSettings.Create;
  // all dictionaries are case insensitive
  fFileNames:=TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  fIgnoredFiles:=TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  fUnits:=TDictionary<string, TDelphiUnit>.Create(TIStringComparer.Ordinal);
  fMainUnit:=nil;
end;

destructor TDelphiProject.Destroy;
begin
  FreeAndNil(fUnits);
  FreeAndNil(fFileNames);
  FreeAndNil(fIgnoredFiles);
  FreeAndNil(fSettings);
end;

function UnitsCompare(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := StrToIntDef(List[Index2], 0) - StrToIntDef(List[Index1], 0)
end;



procedure TDelphiProject.GetClassesSorted(SortCol: TDelphiClassStatType; Ascending: boolean; Classes: TList<TDelphiClass>);
var
  U: TDelphiUnit;
  C: TDelphiClass;
  Comparer: TDelphiClassComparer;
begin
  Classes.Clear;
  for U in fUnits.Values do
    if U.Parsed then
    begin
      for C in U.InterfaceClasses do
        Classes.Add(C);
    end;

  Comparer:=TDelphiClassComparer.Create(SortCol, Ascending);
  try
    Classes.Sort(Comparer);
  finally
    FreeAndNil(Comparer);
  end;
end;

procedure TDelphiProject.GetIgnoredFiles(Strings: TStrings);
var
  SL: TStringList;
  S: String;
begin
  Strings.BeginUpdate;
  try
    SL:=TStringList.Create;
    try
      for S in fIgnoredFiles.Keys do
        SL.Add(S);
      SL.Sort;
      Strings.Assign(SL);
    finally
      FreeAndNil(SL);
    end;
  finally
    Strings.EndUpdate
  end;
end;

procedure TDelphiProject.GetUnitsContainingClass(ClassName: String;
  Units: TStrings);
var
  U: TDelphiUnit;
begin
  Units.Clear;
  for U in fUnits.Values do
    if U.Parsed and U.ContainsClass(ClassName) then
      Units.AddObject(U.Name, U);
end;

procedure TDelphiProject.GetUnitsSorted(SortCol: TDelphiUnitStatType; Ascending: boolean; IncludeExternalUnits: Boolean; Units: TList<TDelphiUnit>);
var
  U: TDelphiUnit;
  Comparer: TDelphiUnitComparer;
begin
  Units.Clear;
  for U in fUnits.Values do
    if U.Parsed or IncludeExternalUnits then
      Units.Add(U);

  Comparer:=TDelphiUnitComparer.Create(SortCol, Ascending);
  try
    Units.Sort(Comparer);
  finally
    FreeAndNil(Comparer);
  end;
end;

procedure TDelphiProject.LoadFromFile(FileName: String);
begin
  fFileNames.Clear;
  fUnits.Clear;
  fSettings.LoadFromFile(FileName);
end;

procedure TDelphiProject.Log(S: String; Level: TLogLevel);
begin
  if Assigned(fLogProc) then
    fLogProc(S, Level);
end;

procedure TDelphiProject.Parse(FileName: String; LogProc: TInfoProc);
var
  Dir: String;
  //IgnoredFile: String;
begin
  fLogProc:=LogProc;
  fUnits.Clear;
  fFileNames.Clear;
  fIgnoredFiles.Clear;
  fMainUnit:=TDelphiUnit.Create;

  if not TFile.Exists(FileName) then
  begin
    Log('Could not find project file "' + FileName + '"');
    Exit;
  end;

  // look in the home folder if not other search dirs
  if fSettings.SearchDirs.Count = 0 then
    CollectFileNames(ExtractFilePath(fSettings.RootFileName))
  else
    for Dir in fSettings.SearchDirs do
      CollectFileNames(TPath.Combine(ExtractFilePath(fSettings.RootFileName), Dir));
  ParseUnit(fMainUnit, FileName, 1);
end;

procedure TDelphiProject.ParsedUsedUnits(ReferringUnit: TDelphiUnit; Depth: Integer);

  procedure ParseRefs(UsesList: TObjectList<TDelphiUnit>; FromInterface: Boolean);
  var
    U       : TDelphiUnit;
    FileName: String;
  begin
    for U in UsesList do
    begin
      if not fFileNames.ContainsKey(U.Name) then
      begin
        if not fIgnoredFiles.ContainsKey(U.Name) then
          fIgnoredFiles.Add(U.Name, U.Name);
      end
      else
      begin
        FileName:=fFileNames.Items[U.Name];
        ParseUnit(U, FileName, Depth);
      end;
      if FromInterface and not U.RefsFromInterfaces.Contains(ReferringUnit) then
        U.RefsFromInterfaces.Add(ReferringUnit)
      else if not U.RefsFromImplementations.Contains(ReferringUnit) then
        U.RefsFromImplementations.Add(ReferringUnit)
    end;
  end;

begin
  ParseRefs(ReferringUnit.InterfaceUses, True);
  ParseRefs(ReferringUnit.ImplementationUses, False);
end;

procedure TDelphiProject.ParseUnit(U: TDelphiUnit; FileName: String; Depth: Integer);

var
  Lex: TLexicalAnalyser;

  function GetQualifiedName: String;
  begin
    Result:=Lex.CurrentSym;
    Lex.GetSym;
    while Lex.OptionalSym('.') do
    begin
      Result:=Result + '.' + Lex.CurrentSym;
      Lex.GetSym;
    end;
  end;

  procedure ParseUsesClause(UseList: TObjectList<TDelphiUnit>);

    function GetOrCreateUnit(Name: String): TDelphiUnit;
    begin
      if not fUnits.TryGetValue(Name, Result) then
      begin
        Result:=TDelphiUnit.Create;
        Result.Name := Name;
        fUnits.Add(Name, Result);
      end;
    end;

  var
    Name: String;
  begin
    Name:=GetQualifiedName;
    UseList.Add(GetOrCreateUnit(Name));
    while Lex.OptionalSym(',') do
    begin
      Name:=GetQualifiedName;
      UseList.Add(GetOrCreateUnit(Name));
    end;
  end;

var
  CurrentClass: TDelphiClass;
  ClassName   : String;
begin
  if U.Parsed then
    Exit;

  Lex:=TLexicalAnalyser.CreateFromFile(FileName);
  try
    Lex.RequiredSym('unit');
    U.Name:=GetQualifiedName;
    U.FileName:=Filename;
    U.Depth:=Depth;
    U.SourceText:=Lex.Text;
    //Log('>> Parsing ' + FileName);
    if not fUnits.ContainsKey(U.Name) then
    begin
      fUnits.Add(U.Name, U);
    end;
    Lex.LogProc:=fLogProc;
    Lex.Logging:=True;
    Lex.SkipTo('interface');
    if Lex.OptionalSym('uses') then
      ParseUsesClause(U.InterfaceUses);

    //Lex.SkipTo('implementation');
    while not Lex.OptionalSym('implementation') do
    begin
      if Lex.SymbolIs('class')  then
      begin
        ClassName:=Lex.PreviousSym(1);
        Lex.GetSym;
        if     not Lex.OptionalSym(';')             // skip forward declares
           and not Lex.OptionalSym('function')  // skip class methods
           and not Lex.OptionalSym('procedure') // skip class methods
        then
        begin
          CurrentClass:=TDelphiClass.Create(ClassName, FileName);
          U.InterfaceClasses.Add(CurrentClass);
          while not Lex.OptionalSym('end') do
          begin
            if Lex.OptionalSym('procedure') and not Lex.OptionalSym('(') then
              CurrentClass.Routines.Add('procedure ' + GetQualifiedName)
            else if Lex.OptionalSym('function') and not Lex.OptionalSym('(') then
              CurrentClass.Routines.Add('function ' + GetQualifiedName)
            else if Lex.OptionalSym('property') then
              CurrentClass.Properties.Add('property ' + GetQualifiedName)
            else
              Lex.GetSym;
          end
        end
      end;

      if Lex.OptionalSym('procedure') and not Lex.OptionalSym('(') then
        U.InterfaceRoutines.Add('procedure ' + GetQualifiedName)
      else if Lex.OptionalSym('function') and not Lex.OptionalSym('(') then
        U.InterfaceRoutines.Add('function ' + GetQualifiedName)
      else
        Lex.GetSym;
    end;

    if Lex.OptionalSym('uses') then
      ParseUsesClause(U.ImplementationUses);

    Lex.SkipToEof;
    U.LineCount:=Lex.LineNo;
    U.Parsed:=True;

    //Log('<< Parsing ' + FileName);
  finally
    FreeAndNil(Lex);
  end;
  ParsedUsedUnits(U, Depth+1)
end;

procedure TDelphiProject.SaveToFile(FileName: String);
begin
  fSettings.SaveToFile(FileName);
end;

procedure TDelphiProject.UnParse(Strings: TStrings);
var
  U: TDelphiUnit;
begin
  for U in fUnits.Values do
    U.Unparse(Strings);
end;

end.
