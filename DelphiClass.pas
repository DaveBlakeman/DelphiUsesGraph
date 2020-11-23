unit DelphiClass;

interface

uses
  Classes;

type
  TDelphiClass = class
  private
    fName    : String;
    fRoutines: TStringList;
  public
    constructor Create(Name: String);
    destructor Destroy; override;

    property Name : String read fName;
    property Routines: TStringList read fRoutines;
  end;

implementation

uses
  SysUtils;

{ TDelphiClass }

constructor TDelphiClass.Create(Name: String);
begin
  fName:=Name;
  fRoutines:=TStringList.Create;
end;

destructor TDelphiClass.Destroy;
begin
  FreeAndNil(fRoutines);
  inherited;
end;

end.
