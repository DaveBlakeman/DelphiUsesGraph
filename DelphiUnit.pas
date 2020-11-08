unit DelphiUnit;

interface

uses
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Classes;

type

  TDelphiUnitStatType = (
    duName,
    duFileName,
    duIntfUses,
    duImplUses,
    duIntfRefs,
    duImplRefs,
    duLineCount,
    duWeighting,
    duDepth,
    duDepthDiff,
    duRoutines,
    duIntfDependency,
    duImplDependency,
    duCyclic
  );

  TDelphiUnitFilter = (dufInterfacesOnly, dufAll);

  TLazyBool = (lbNotCalculated, lbNo, lbYes);


  TDelphiUnit = class
  private
    fName                   : String;
    fFileName               : String;
    fDepth                  : Integer;
    fParsed                 : Boolean;
    fLineCount              : Integer;
    fMaxDependency          : Integer; // the cumulative dependency depth of units I use
    fMaxInterfaceDependency : Integer;
    fContainsCycles         : TLazyBool;
    fInterfaceUses          : TObjectList<TDelphiUnit>;
    fInterfaceRoutines      : TStringList;
    fImplementationUses     : TObjectList<TDelphiUnit>;

    fRefsFromInterfaces     : TObjectList<TDelphiUnit>;  // other units referring to me form their Interface
    fRefsFromImplementations: TObjectList<TDelphiUnit>;  // other units referring to me form their Implementation

    class procedure GetDeepestDependencyPath(UnitToProcess: TDelphiUnit; Strings: TStrings);
    class procedure GetDependencyTree(
      UnitToProcess: TDelphiUnit;
      Strings: TStrings;
      Filter: TDelphiUnitFilter;
      Level: Integer;
      MaxDepth: Integer
    );
    class function UnitContainsCycles(UnitToProcess: TDelphiUnit): Boolean;
    function GetMaxDependency: Integer;
    function GetContainsCycles: Boolean;
    function GetMaxInterfaceDependency: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    class function DeepestDependentUnit(UnitToProcess: TDelphiUnit): TDelphiUnit; static;

    procedure Clear;

    procedure GetStatDetails(StatType: TDelphiUnitStatType; Strings: TStrings);

    procedure Unparse(Strings: TStrings);

    function Weighting: Integer;

    function DepthDifferential: Integer;

    property Name                   : String                   read fName      write fName;
    property FileName               : String                   read fFileName  write fFileName;
    property Depth                  : Integer                  read fDepth     write fDepth;
    property LineCount              : Integer                  read fLineCount write fLineCount;
    property Parsed                 : Boolean                  read fParsed    write fParsed;
    property ContainsCycles         : Boolean                  read GetContainsCycles;
    property MaxDependency          : Integer                  read GetMaxDependency;
    property MaxInterfaceDependency : Integer                  read GetMaxInterfaceDependency;
    property InterfaceUses          : TObjectList<TDelphiUnit> read fInterfaceUses;
    property InterfaceRoutines      : TStringList              read fInterfaceRoutines;
    property ImplementationUses     : TObjectList<TDelphiUnit> read fImplementationUses;
    property RefsFromInterfaces     : TObjectList<TDelphiUnit> read fRefsFromInterfaces ;
    property RefsFromImplementations: TObjectList<TDelphiUnit> read fRefsFromImplementations;
  end;

  TDelphiUnitComparer = class(TComparer<TDelphiUnit>)
  private
    fSortCol: TDelphiUnitStatType;
    fAscending: Boolean;
  public
    constructor Create(SortCol: TDelphiUnitStatType; Ascending: Boolean);
    function Compare(const Left, Right: TDelphiUnit): Integer; override;
  end;


implementation

uses
  System.Math,
  SysUtils,
  StrUtils;

{ TDelphiUnit }

procedure TDelphiUnit.Clear;
begin
  fName:='';
  fFileName:='';
  fDepth:=0;
  fParsed:=False;
  fLineCount:=0;
  fMaxInterfaceDependency:=-1;
  fMaxDependency:=-1;
  fContainsCycles:=lbNotCalculated;
  fInterfaceUses.Clear;
  fInterfaceRoutines.Clear;
  fImplementationUses.Clear;
  fRefsFromInterfaces.Clear;
  fRefsFromImplementations.Clear;
end;

constructor TDelphiUnit.Create;
begin
  fName:='';
  fFileName:='';
  fDepth:=0;
  fParsed:=False;
  fLineCount:=0;
  fMaxInterfaceDependency:=-1;
  fMaxDependency:=-1;
  fContainsCycles          :=lbNotCalculated;
  fInterfaceUses           := TObjectList<TDelphiUnit>.Create(False);
  fInterfaceRoutines       :=TStringList.Create;
  fImplementationUses      := TObjectList<TDelphiUnit>.Create(False);
  fRefsFromInterfaces      := TObjectList<TDelphiUnit>.Create(False);
  fRefsFromImplementations := TObjectList<TDelphiUnit>.Create(False);
end;

function TDelphiUnit.DepthDifferential: Integer;
var
  U: TDelphiUnit;
begin
  Result:=0;
  for U in fInterfaceUses do
    if U.Depth < fDepth then
      Result:=Min(Result, U.Depth - fDepth);
  for U in fImplementationUses do
    if U.Depth < fDepth then
      Result:=Min(Result, U.Depth - fDepth);
end;

destructor TDelphiUnit.Destroy;
begin
  FreeAndNil(fInterfaceUses);
  FreeAndNil(fInterfaceRoutines);
  FreeAndNil(fImplementationUses);
  FreeAndNil(fRefsFromInterfaces);
  FreeAndNil(fRefsFromImplementations);
end;

function TDelphiUnit.GetMaxDependency: Integer;
var
  U: TDelphiUnit;
begin
  if fMaxDependency = -1 then
  begin
    if fParsed then
    begin
      fMaxDependency:=0;
      for U in fInterfaceUses do
      begin
        if U.MaxDependency <> -1 then
          fMaxDependency:=Max(fMaxDependency, U.MaxDependency+1);
      end;
      for U in fImplementationUses do
      begin
        if U.MaxDependency <> -1 then
          fMaxDependency:=Max(fMaxDependency, U.MaxDependency+1);
      end;
    end;
  end;
  Result:=fMaxDependency;
end;

function TDelphiUnit.GetMaxInterfaceDependency: Integer;
var
  U: TDelphiUnit;
begin
  if fMaxInterfaceDependency = -1 then
  begin
    if fParsed then
    begin
      fMaxInterfaceDependency:=0;
      for U in fInterfaceUses do
      begin
        if U.MaxInterfaceDependency <> -1 then
          fMaxInterfaceDependency:=Max(fMaxInterfaceDependency, U.MaxInterfaceDependency+1);
      end;
    end;
  end;
  Result:=fMaxInterfaceDependency;
end;

class function TDelphiUnit.DeepestDependentUnit(UnitToProcess: TDelphiUnit): TDelphiUnit;
var
  U: TDelphiUnit;
  MaxFound: Integer;
begin
  Result:=nil;
  MaxFound:=-1;
  for U in UnitToProcess.InterfaceUses do
    if U.MaxDependency > MaxFound then
    begin
      MaxFound:=U.MaxDependency;
      Result:=U;
    end;
  for U in UnitToProcess.ImplementationUses do
    if U.MaxDependency > MaxFound then
    begin
      MaxFound:=U.MaxDependency;
      Result:=U;
    end;
end;

function TDelphiUnit.GetContainsCycles: Boolean;
begin
  if fContainsCycles = lbNotCalculated then
    if UnitContainsCycles(Self) then
      fContainsCycles:=lbYes
    else
      fContainsCycles:=lbNo;

  Result:= fContainsCycles = lbYes;
end;

class procedure TDelphiUnit.GetDeepestDependencyPath(UnitToProcess: TDelphiUnit; Strings: TStrings);

var
  TallestChild: TDelphiUnit;
begin
  TallestChild := DeepestDependentUnit(UnitToProcess);

  if TallestChild = nil then
    Exit;

  if TallestChild.MaxDependency > UnitToProcess.MaxDependency then
    Strings.AddObject('Cycle found: ' + TallestChild.Name + ', dependency = ' + IntToStr(TallestChild.MaxDependency), TallestChild)
  else
  begin
    Strings.AddObject(TallestChild.Name + ', dependency = ' + IntToStr(TallestChild.MaxDependency), TallestChild);
    GetDeepestDependencyPath(TallestChild, Strings);
  end;
end;

class procedure TDelphiUnit.GetDependencyTree(
  UnitToProcess: TDelphiUnit;
  Strings: TStrings;
  Filter: TDelphiUnitFilter;
  Level: Integer;
  MaxDepth: Integer
);
const
  cIndent = 8;

var
  UnitsAlreadyAdded: TObjectList<TDelphiUnit>;

  procedure ProcessUnit(UnitToProcess: TDelphiUnit; Level: Integer);

    procedure ProcessUsedUnits(Indent: String; L: TObjectList<TDelphiUnit>);
    var
      U: TDelphiUnit;
    begin
      for U in UnitToProcess.InterfaceUses do
        if not U.Parsed then
          // skip
        else if U.MaxDependency >= UnitToProcess.MaxDependency then
          Strings.AddObject(Indent + 'Cycle found: ' + U.Name, U)
        else
          ProcessUnit(U, Level+1);
    end;

  var
    BaseIndent: String;
    Indent: String;
    Caption: String;
  begin
    if UnitsAlreadyAdded.IndexOf(UnitToProcess) <> -1 then
      Exit;

    UnitsAlreadyAdded.Add(UnitToProcess);

    if Level >= MaxDepth then
      Exit;

    BaseIndent:=StringOfChar(' ', Level*cIndent);
    Indent:=BaseIndent + StringOfChar(' ', cIndent div 2);
    if Filter = dufInterfacesOnly then
      Caption := UnitToProcess.Name + '(' + IntToStr(UnitToProcess.MaxInterfaceDependency) + ')'
    else
      Caption := UnitToProcess.Name + '(' + IntToStr(UnitToProcess.MaxDependency) + ')';

    Strings.AddObject(BaseIndent + Caption, UnitToProcess);

    Strings.AddObject(Indent + 'Interface', nil);
    ProcessUsedUnits(Indent, UnitToProcess.InterfaceUses);

    if (Filter = dufAll) then
    begin
      Strings.AddObject(Indent + 'Implementation', nil);
      ProcessUsedUnits(Indent, UnitToProcess.ImplementationUses);
    end;
  end;

begin
  UnitsAlreadyAdded:=TObjectList<TDelphiUnit>.Create(False);
  try
    ProcessUnit(UnitToProcess, Level);
  finally
    FreeAndNil(UnitsAlreadyAdded);
  end
end;

class function TDelphiUnit.UnitContainsCycles(UnitToProcess: TDelphiUnit): Boolean;

var
  U: TDelphiUnit;
begin
  Result:=False;
  for U in UnitToProcess.InterfaceUses do
    if not U.Parsed then
      // skip
    else if U.MaxDependency >= UnitToProcess.MaxDependency then
      Exit(True)
    else
      if UnitContainsCycles(U) then
        Exit(True);

  for U in UnitToProcess.ImplementationUses do
    if not U.Parsed then
      // skip
    else if U.MaxDependency >= UnitToProcess.MaxDependency then
      Exit(True)
    else
      if UnitContainsCycles(U) then
        Exit(True);
end;

procedure TDelphiUnit.GetStatDetails(StatType: TDelphiUnitStatType; Strings: TStrings);
var
  U: TDelphiUnit;
begin
  Strings.Clear;
  case StatType of
    duName          : Strings.AddObject(Name, Self);
    duFileName      : Strings.AddObject(FileName, Self);
    duIntfUses      : for U in InterfaceUses do
                        Strings.AddObject(U.Name + ', dependency = ' + IntToStr(U.MaxDependency), U);
    duImplUses      : for U in ImplementationUses do
                        Strings.AddObject(U.Name + ', dependency = ' + IntToStr(U.MaxDependency), U);
    duIntfRefs      : for U in RefsFromInterfaces do
                        Strings.AddObject(U.Name, U);
    duImplRefs      : for U in RefsFromImplementations do
                        Strings.AddObject(U.Name, U);
    duLineCount     : Strings.AddObject(IntToStr(LineCount), Self);
    duWeighting     : Strings.AddObject(IntToStr(Weighting), Self);
    duDepth         : Strings.AddObject(IntToStr(Depth), Self);
    duDepthDiff     : Strings.AddObject(IntToStr(DepthDifferential), Self);
    duRoutines      : Strings.Assign(InterfaceRoutines);
    duIntfDependency: GetDependencyTree(Self, Strings, dufInterfacesOnly, 0, 10);
    duImplDependency: GetDependencyTree(Self, Strings, dufAll, 0, 10);
    duCyclic        : Strings.Add(BoolToStr(ContainsCycles, True));
    else
      raise Exception.Create('TDelphiUnitComparer.Compare: unknown comparison type');
  end
end;

procedure TDelphiUnit.Unparse(Strings: TStrings);

  function UsesList(L: TObjectList<TDelphiUnit>): String;
  var
    U: TDelphiUnit;
  begin
    Result:='';
    for U in L do
      Result:=Result + U.Name + ' ';
  end;

begin
  if (fInterfaceUses.Count + fImplementationUses.Count > 0) then
  begin
    Strings.Add('Unit ' + fName);
    Strings.Add('  Interface');
    Strings.Add('    ' + UsesList(fInterfaceUses));
    Strings.Add('  Implementation');
    Strings.Add('    ' + UsesList(fImplementationUses));
    Strings.Add('  Referred to by:');
    Strings.Add('    From Interfaces: ');
    Strings.Add('    ' + UsesList(fRefsFromInterfaces));
    Strings.Add('    From Implementations: ');
    Strings.Add('    ' + UsesList(fRefsFromImplementations));
  end;
end;

function TDelphiUnit.Weighting: Integer;
begin
  // experimental, but an idea of implementation complexity
  Result:=fImplementationUses.Count * fRefsFromImplementations.Count;
end;

function TDelphiUnitComparer.Compare(const Left, Right: TDelphiUnit): Integer;

  function CompareIntegers(I1: Integer; I2: Integer): Integer;
  begin
    if fAscending then
      Result:= I1 - I2
    else
      Result:= I2 - I1
  end;

  function CompareStrings(S1: String; S2: String): Integer;
  begin
    if fAscending then
      Result:= CompareStr(S1, S2)
    else
      Result:= CompareStr(S2, S1)
  end;

  function CompareBooleans(B1: Boolean; B2: Boolean): Integer;
  begin
    if fAscending then
      Result:= ord(B1) - Ord(B2)
    else
      Result:= ord(B2) - Ord(B1)
  end;

begin
  case fSortCol of
    duName          : Result := CompareStrings(Left.Name, Right.Name);
    duFileName      : Result := CompareStrings(Left.FileName, Right.FileName);
    duIntfUses      : Result := CompareIntegers(Left.InterfaceUses.Count, Right.InterfaceUses.Count);
    duImplUses      : Result := CompareIntegers(Left.ImplementationUses.Count, Right.ImplementationUses.Count);
    duIntfRefs      : Result := CompareIntegers(Left.RefsFromInterfaces.Count, Right.RefsFromInterfaces.Count);
    duImplRefs      : Result := CompareIntegers(Left.RefsFromImplementations.Count, Right.RefsFromImplementations.Count);
    duLineCount     : Result := CompareIntegers(Left.LineCount, Right.LineCount);
    duWeighting     : Result := CompareIntegers(Left.Weighting, Right.Weighting);
    duDepth         : Result := CompareIntegers(Left.Depth, Right.Depth);
    duDepthDiff     : Result := CompareIntegers(Left.DepthDifferential, Right.DepthDifferential);
    duRoutines      : Result := CompareIntegers(Left.InterfaceRoutines.Count, Right.InterfaceRoutines.Count);
    duIntfDependency: Result := CompareIntegers(Left.MaxInterfaceDependency, Right.MaxInterfaceDependency);
    duImplDependency: Result := CompareIntegers(Left.MaxDependency, Right.MaxDependency);
    duCyclic        : Result := CompareBooleans(Left.ContainsCycles, Right.ContainsCycles);
    else
      raise Exception.Create('TDelphiUnitComparer.Compare: unknown comparison type');
  end
end;


constructor TDelphiUnitComparer.Create(SortCol: TDelphiUnitStatType; Ascending: Boolean);
begin
  fSortCol:=SortCol;
  fAscending:=Ascending;
end;

end.
