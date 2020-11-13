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
  System.JSON,
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
  Text    : String;
  JSON    : TJSONValue;
  DirArray: TJSONArray;
  Dir     : TJSONValue;
begin
  fRootFileName:='';
  fSearchDirs.Clear;
  Text := TFile.ReadAllText(FileName);
  JSON := TJSonObject.ParseJSONValue(Text);
  try
    if JSON is TJSONObject then
    begin
      fRootFileName:=(JSON as TJSONObject).GetValue<String>('RootFileName');
      DirArray:=(JSON as TJSONObject).GetValue('SearchDirs') as TJSONArray;
      if DirArray <> nil then
      begin
        for Dir in DirArray do
          fSearchDirs.Add(Dir.Value);
      end;
    end;
  finally
    FreeAndNil(JSON);
  end;
end;

procedure TProjectSettings.SaveToFile(FileName: String);
var
  JSON: TJSONObject;
  JSONDirs: TJsonArray;
  Dir    : String;
begin
  JSON:=TJSONObject.Create;
  try

    JSON.AddPair('RootFileName', fRootFileName);

    JSONDirs:=TJsonArray.Create;
    for Dir in fSearchDirs do
      JSONDirs.Add(Dir);
    JSON.AddPair('SearchDirs', JSONDirs);
    TFile.WriteAllText(fileName, JSON.ToJSON());

  finally
    FreeAndNil(JSON);
  end;
end;

end.
