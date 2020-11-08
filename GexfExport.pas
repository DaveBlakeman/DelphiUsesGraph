unit GexfExport;

interface

uses
  System.Classes,
  DelphiProject,
  DelphiUnit;

type

  TGexfExportOption = (gexfExportIntfUses, gexfExportImplUses);

  TGexfExportOptions = set of TGexfExportOption;

  TGexfExport = class
  private

  public
    constructor Create;
    destructor Destroy; override;

    procedure ExportProjectToFile(Project: TDelphiProject; FileName: String; Options: TGexfExportOptions);
    procedure ExportProjectToStrings(Project: TDelphiProject; Strings: TStrings; Options: TGexfExportOptions);
  end;

implementation

uses
  System.SysUtils;


constructor TGexfExport.Create;
begin

end;

destructor TGexfExport.Destroy;
begin
  inherited;
end;

procedure TGexfExport.ExportProjectToFile(Project: TDelphiProject; FileName: String; Options: TGexfExportOptions);
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


procedure ExportGraphToStrings(Project: TDelphiProject; Strings: TStrings; Options: TGexfExportOptions);

  procedure ExportIntfUses(U: TDelphiUnit; var EdgeId: Integer);
  var
    RefUnit: TDelphiUnit;
  begin
    for RefUnit in U.InterfaceUses do
      if RefUnit.Parsed then
      begin
        Strings.Add('            <edge id="' + IntToStr(EdgeId) + '" source="' + IntToStr(Integer(U)) + '" target="' + IntToStr(Integer(RefUnit)) + '" />');
        Inc(EdgeId);
      end;
  end;

  procedure ExportImplUses(U: TDelphiUnit; var EdgeId: Integer);
  var
    RefUnit: TDelphiUnit;
  begin
    for RefUnit in U.ImplementationUses do
      if RefUnit.Parsed then
      begin
        Strings.Add('            <edge id="' + IntToStr(EdgeId) + '" source="' + IntToStr(Integer(U)) + '" target="' + IntToStr(Integer(RefUnit)) + '" />');
        Inc(EdgeId);
      end;
  end;

var
  U      : TDelphiUnit;
  EdgeId : Integer;
begin
  Strings.Add('     <graph mode="static" defaultedgetype="directed">');
  Strings.Add('        <nodes>');
  for U in Project.Units.Values do
    if U.Parsed then
      Strings.Add('            <node id="' + IntToStr(Integer(U)) + '" label="' + U.Name + '" />');
  Strings.Add('        </nodes>');

  EdgeId:=0;
  Strings.Add('        <edges>');
  for U in Project.Units.Values do
    if U.Parsed then
    begin
      if gexfExportIntfUses in Options then
        ExportIntfUses(U, EdgeId);

      if gexfExportImplUses in Options then
        ExportImplUses(U, EdgeId);
    end;
  Strings.Add('        </edges>');
  Strings.Add('    </graph>');
end;

procedure TGexfExport.ExportProjectToStrings(Project: TDelphiProject; Strings: TStrings; Options: TGexfExportOptions);
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    Strings.Add('<?xml version="1.0" encoding="UTF-8"?>');
    Strings.Add('<gexf xmlns="http://www.gexf.net/1.2draft" version="1.2">');
    Strings.Add('  <meta lastmodifieddate="2020-10-31">');
    Strings.Add('    <creator>UsesGraph</creator>');
    Strings.Add('    <description>A delphi Project</description>');
    ExportGraphToStrings(Project, Strings, Options);
    Strings.Add('  </meta>');
    Strings.Add('</gexf>');
  finally
    Strings.EndUpdate;
  end;
end;

end.
