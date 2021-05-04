unit DelphiClass;

interface

uses
  System.Generics.Defaults,
  System.Generics.Collections,
  Classes;

type
  TDelphiClassStatType = (
    dcName,
    dcPrivateRoutines,
    dcProtectedRoutines,
    dcPublicRoutines,
    dcPublishedRoutines,
    dcProperties,
    dcFileName,
    dcUnitsReferencing
  );

  TDelphiVisibility = (dvPrivate, dvProtected, dvPublic, dvPublished);

  TDelphiClass = class
  private
    fName             : String;
    fFileName         : String;
    fPrivateRoutines  : TStringList;
    fProtectedRoutines: TStringList;
    fPublicRoutines   : TStringList;
    fPublishedRoutines: TStringList;
    fProperties       : TStringList;
    fUnitsReferencing : TStringList; (* TDelphiUnit *)
  public
    constructor Create(Name: String; FileName: String);
    destructor Destroy; override;

    procedure GetStatDetails(StatType: TDelphiClassStatType; Strings: TStrings);

    function TotalRoutines: Integer;

    property Name              : String      read fName;
    property FileName          : String      read fFileName;
    property PrivateRoutines   : TStringList read fPrivateRoutines;
    property ProtectedRoutines : TStringList read fProtectedRoutines;
    property PublicRoutines    : TStringList read fPublicRoutines;
    property PublishedRoutines : TStringList read fPublishedRoutines;
    property Properties        : TStringList read fProperties;
    property UnitsReferencing  : TStringList read fUnitsReferencing;
  end;

  TDelphiClassComparer = class(TComparer<TDelphiClass>)
  private
    fSortCol: TDelphiClassStatType;
    fAscending: Boolean;
  public
    constructor Create(SortCol: TDelphiClassStatType; Ascending: Boolean);
    function Compare(const Left, Right: TDelphiClass): Integer; override;
  end;

const
  cDelphiVisibility: array[TDelphiVisibility] of string = ('private', 'protected', 'public', 'published');

implementation

uses
  SysUtils;

{ TDelphiClass }

constructor TDelphiClass.Create(Name: String; FileName: String);
begin
  fName:=Name;
  fFileName:=FileName;
  fPrivateRoutines  :=TStringList.Create;
  fProtectedRoutines:=TStringList.Create;
  fPublicRoutines   :=TStringList.Create;
  fPublishedRoutines:=TStringList.Create;
  fProperties:=TStringList.Create;
  fUnitsReferencing:=TStringList.Create;
end;

destructor TDelphiClass.Destroy;
begin
  FreeAndNil(fPrivateRoutines);
  FreeAndNil(fProtectedRoutines);
  FreeAndNil(fPublicRoutines);
  FreeAndNil(fPublishedRoutines);
  FreeAndNil(fProperties);
  FreeAndNil(fUnitsReferencing);
  inherited;
end;

procedure TDelphiClass.GetStatDetails(StatType: TDelphiClassStatType; Strings: TStrings);
begin
  Strings.Clear;
  case StatType of
    dcName              : Strings.AddObject(Name, Self);
    dcFileName          : Strings.AddObject(FileName, Self);
    dcPrivateRoutines   : Strings.Assign(fPrivateRoutines);
    dcProtectedRoutines : Strings.Assign(fProtectedRoutines);
    dcPublicRoutines    : Strings.Assign(fPublicRoutines);
    dcPublishedRoutines : Strings.Assign(fPublishedRoutines);
    dcProperties        : Strings.Assign(fProperties);
    dcUnitsReferencing  : Strings.Assign(fUnitsReferencing);
  else
    raise Exception.Create('TDelphiClass.GetStatDetails: unknown stat type');
  end
end;

function TDelphiClass.TotalRoutines: Integer;
begin
  Result:=fPrivateRoutines.Count + fProtectedRoutines.Count + fPublicRoutines.Count + fPublishedRoutines.Count
end;

{ TDelphiClassComparer }

function TDelphiClassComparer.Compare(const Left, Right: TDelphiClass): Integer;

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
    dcName             : Result := CompareStrings(Left.Name, Right.Name);
    dcFileName         : Result := CompareStrings(Left.FileName, Right.FileName);
    dcPrivateRoutines  : Result := CompareIntegers(Left.PrivateRoutines.Count, Right.PrivateRoutines.Count);
    dcProtectedRoutines: Result := CompareIntegers(Left.ProtectedRoutines.Count, Right.ProtectedRoutines.Count);
    dcPublicRoutines   : Result := CompareIntegers(Left.PublicRoutines.Count, Right.PublicRoutines.Count);
    dcPublishedRoutines: Result := CompareIntegers(Left.PublishedRoutines.Count, Right.PublishedRoutines.Count);
    dcProperties       : Result := CompareIntegers(Left.Properties.Count, Right.Properties.Count);
    dcUnitsReferencing : Result := CompareIntegers(Left.UnitsReferencing.Count, Right.UnitsReferencing.Count);
  else
    raise Exception.Create('TDelphiClassComparer.Compare: unknown comparison type');
  end
end;


constructor TDelphiClassComparer.Create(SortCol: TDelphiClassStatType;
  Ascending: Boolean);
begin
  fSortCol:=SortCol;
  fAscending:=Ascending;
end;

end.
