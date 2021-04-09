unit JSONExport;

interface

uses
  System.Classes,
  DelphiProject,
  DelphiUnit;

type

  TJSONExportOption = (JSONExportIntfUses, JSONExportImplUses);

  TJSONExportOptions = set of TJSONExportOption;

  TJSONExport = class
  private

  public
    constructor Create;
    destructor Destroy; override;

    procedure ExportProjectToFile(Project: TDelphiProject; FileName: String; Options: TJSONExportOptions);
    procedure ExportProjectToStrings(Project: TDelphiProject; Strings: TStrings; Options: TJSONExportOptions);
  end;

implementation

uses
  System.SysUtils,
  JsonDataObjects;

const
  cGraphId      = 'F7F603A5-15E4-4B7B-9155-6B311F93344E';
  cNodeType     = '28324482-311B-4B60-8915-ED3F0D289195';
  cIntfEdgeType = 'E087D745-F82B-4994-9876-BBE79C6BEBA8';
  cImplEdgeType = 'A955057F-B3A2-4217-A47A-FD96A5463369';

constructor TJSONExport.Create;
begin

end;

destructor TJSONExport.Destroy;
begin
  inherited;
end;

procedure TJSONExport.ExportProjectToFile(Project: TDelphiProject; FileName: String; Options: TJSONExportOptions);
var
  Strings: TStringList;
begin
  Strings:=TStringList.Create;
  try
    ExportProjectToStrings(Project, Strings, Options);
    Strings.SaveToFile(FileName);
  finally
    FreeAndNil(Strings);
  end;
end;


procedure ExportGraphToStrings(Project: TDelphiProject; Strings: TStrings; Options: TJSONExportOptions);

  procedure ExportIntfUses(JSON: TJSONArray; U: TDelphiUnit; var EdgeId: Integer);
  var
    RefUnit: TDelphiUnit;
    Edge: TJSONObject;
  begin
    for RefUnit in U.InterfaceUses do
      if RefUnit.Parsed then
      begin
        Edge:=TJSONObject.Create;
        Edge.S['id'   ]:= IntToStr(EdgeId);
        Edge.S['from' ]:= IntToStr(Integer(U));
        Edge.S['to'   ]:= IntToStr(Integer(RefUnit));
        Edge.I['directed' ]:= 1;
        Edge.S['name' ]:= 'Intf Ref';
        Edge.S['type_id'] := cIntfEdgeType;
        Edge.O['properties'] := TJSONObject.Create;
        Edge.O['reference'] := nil;
        JSON.Add(Edge);
        Inc(EdgeId);
      end;
  end;

  procedure ExportImplUses(JSON: TJSONArray; U: TDelphiUnit; var EdgeId: Integer);
  var
    RefUnit: TDelphiUnit;
    Edge: TJSONObject;
  begin
    for RefUnit in U.ImplementationUses do
      if RefUnit.Parsed then
      begin
        Edge:=TJSONObject.Create;
        Edge.S['id'   ]:=  IntToStr(EdgeId);
        Edge.S['from' ]:=  IntToStr(Integer(U));
        Edge.S['to'   ]:=  IntToStr(Integer(RefUnit));
        Edge.I['directed' ]:= 1;
        Edge.S['name' ]:=  'Impl Ref';
        Edge.S['type_id'] := cImplEdgeType;
        Edge.O['properties'] := TJSONObject.Create;
        Edge.O['reference'] := nil;
        JSON.Add(Edge);
        Inc(EdgeId);
      end;
  end;

  function ExportNodeTypes: TJSONArray;
  var
    NodeType: TJSONObject;
  begin
    Result   :=TJSONArray.Create;
    NodeType   :=TJSONObject.Create;
    NodeType.S['id'] := cNodeType;
    NodeType.S['name'] := 'Delphi Unit';
    NodeType.A['properties'] := TJSONArray.Create;
    Result.Add(NodeType);
  end;

  function ExportEdgeTypes: TJSONArray;
  var
    IntfEdgeType: TJSONObject;
    ImplEdgeType: TJSONObject;
  begin
    Result   :=TJSONArray.Create;

    IntfEdgeType   :=TJSONObject.Create;
    IntfEdgeType.S['id'] := cIntfEdgeType;
    IntfEdgeType.S['name'] := 'Intf Ref';
    IntfEdgeType.A['properties'] := TJSONArray.Create;
    Result.Add(IntfEdgeType);

    ImplEdgeType   :=TJSONObject.Create;
    ImplEdgeType.S['id'] := cImplEdgeType;
    ImplEdgeType.S['name'] := 'Impl Ref';
    ImplEdgeType.A['properties'] := TJSONArray.Create;
    Result.Add(ImplEdgeType);
  end;

  function ExportNodes: TJSONArray;

    function ExportNode(U: TDelphiUnit): TJSONObject;
    begin
      Result:=TJSONObject.Create;
      Result.S['id'  ] := IntToStr(Integer(U));
      Result.S['type'] := 'Unit';
      Result.S['type_id'] := cNodeType;
      Result.S['name'] := U.Name;
      Result.A['properties'] := TJSONArray.Create;
      Result.O['reference'] := nil;
    end;

  var
    U       : TDelphiUnit;
  begin
    Result   :=TJSONArray.Create;
    for U in Project.Units.Values do
      if U.Parsed then
        Result.Add(ExportNode(U));
  end;

  function ExportEdges: TJSONArray;

  var
    U       : TDelphiUnit;
    EdgeId  : Integer;
  begin
    Result   :=TJSONArray.Create;
    EdgeId:=0;
    for U in Project.Units.Values do
      if U.Parsed then
      begin
        if JSONExportIntfUses in Options then
          ExportIntfUses(Result, U, EdgeId);

        if JSONExportImplUses in Options then
          ExportImplUses(Result, U, EdgeId);
      end;
  end;

var
  JSON    : TJSONObject;
  Graph  : TJSONObject;
begin
  JSON   := TJSONObject.Create;
  try

    Graph   :=TJSONObject.Create;
    Graph.S['id'] := cGraphId;
    Graph.S['name'] := 'Unit Relations for ' + Project.MainUnit.Name;
    Graph.I['status'] := 0;
    Graph.A['nodeTypes'] := ExportNodeTypes;
    Graph.A['nodes' ]    := ExportNodes;
    Graph.A['edgeTypes'] := ExportEdgeTypes;
    Graph.A['edges' ]    := ExportEdges;

    JSON.O ['graph' ]    := Graph;
    JSON.SaveToLines( Strings );
  finally
    FreeAndNil(JSON);
  end
end;

procedure TJSONExport.ExportProjectToStrings(Project: TDelphiProject; Strings: TStrings; Options: TJSONExportOptions);
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    ExportGraphToStrings(Project, Strings, Options);
  finally
    Strings.EndUpdate;
  end;
end;

end.
