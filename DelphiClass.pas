unit DelphiClass;

interface

uses
  System.Generics.Defaults,
  System.Generics.Collections,
  Classes;

type
  TDelphiClass = class
  private
    fName    : String;
    fFileName: String;
    fRoutines: TStringList;
    fProperties: TStringList;
  public
    constructor Create(Name: String; FileName: String);
    destructor Destroy; override;

    property Name      : String read fName;
    property FileName  : String read fFileName;
    property Routines  : TStringList read fRoutines;
    property Properties: TStringList read fProperties;
  end;

  TDelphiClassStatType = (
    dcName,
    dcRoutines,
    dcProperties,
    dcFileName
  );

  TDelphiClassComparer = class(TComparer<TDelphiClass>)
  private
    fSortCol: TDelphiClassStatType;
    fAscending: Boolean;
  public
    constructor Create(SortCol: TDelphiClassStatType; Ascending: Boolean);
    function Compare(const Left, Right: TDelphiClass): Integer; override;
  end;

implementation

uses
  SysUtils;

{ TDelphiClass }

constructor TDelphiClass.Create(Name: String; FileName: String);
begin
  fName:=Name;
  fFileName:=FileName;
  fRoutines:=TStringList.Create;
  fProperties:=TStringList.Create;
end;

destructor TDelphiClass.Destroy;
begin
  FreeAndNil(fRoutines);
  FreeAndNil(fProperties);
  inherited;
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
    dcName          : Result := CompareStrings(Left.Name, Right.Name);
    dcFileName      : Result := CompareStrings(Left.FileName, Right.FileName);
    dcRoutines      : Result := CompareIntegers(Left.Routines.Count, Right.Routines.Count);
    dcProperties    : Result := CompareIntegers(Left.Properties.Count, Right.Properties.Count);
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
