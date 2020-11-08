program UsesGraph;

uses
  Vcl.Forms,
  Main in 'Main.pas' {FormMain},
  DelphiUnit in 'DelphiUnit.pas',
  LexicalAnalyser in 'LexicalAnalyser.pas',
  DelphiProject in 'DelphiProject.pas',
  ProjectSettings in 'ProjectSettings.pas',
  GexfExport in 'GexfExport.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
