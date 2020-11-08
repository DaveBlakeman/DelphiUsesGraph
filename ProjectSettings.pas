unit ProjectSettings;

interface

uses
  Classes;

type

  TProjectSettings = class
  private
    fRootFileName: String;
    fSearchDirs: TStrings;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(FileName: String);
    procedure SaveToFile(FileName: String);

    property RootFileName: String   read fRootFileName write fRootFileName;
    property SearchDirs: TStrings  read fSearchDirs;

  end;

implementation

uses
  IoUtils,
  JsonDataObjects,
  SysUtils;

{ TProjectSettings }

constructor TProjectSettings.Create;
begin
  fRootFileName:='';
  fSearchDirs:=TStringList.Create;
end;

destructor TProjectSettings.Destroy;
begin
  FreeAndNil(fSearchDirs);
  inherited;
end;

procedure TProjectSettings.LoadFromFile(FileName: String);
var
  Text  : String;
  JSON  : TJSONObject;
  Dirs  : TJSONArray;
  I     : Integer;
begin
  fRootFileName:='';
  fSearchDirs.Clear;
  Text := TFile.ReadAllText(FileName);
  JSON := TJSONObject.Parse(Text) as TJSONObject;
  try
    fRootFileName:=JSON.S['RootFileName'];
    Dirs:=JSON.A['SearchDirs'];
    if (Dirs <> nil) then
    begin
      for I:=0 to Dirs.Count-1 do
        fSearchDirs.Add(Dirs.S[I]);
    end
  finally
    FreeAndNil(JSON);
  end;
end;

procedure TProjectSettings.SaveToFile(FileName: String);
var
  JSON: TJSONObject;
  JsonDirs: TJsonArray;
  Dir    : String;
begin
  JSON:=TJSONObject.Create;
  try
    JSON.S['RootFileName']:= fRootFileName;

    JsonDirs:=TJsonArray.Create;
    for Dir in fSearchDirs do
      JsonDirs.Add(Dir);
    JSON.A['SearchDirs']:=JsonDirs;

    JSON.SaveToFile(Filename, False);
  finally
    FreeAndNil(JSON);
  end;
end;

end.
