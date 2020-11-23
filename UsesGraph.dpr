program UsesGraph;
{$WARN DUPLICATE_CTOR_DTOR OFF}
uses
  Vcl.Forms,
  Main in 'Main.pas' {FormMain},
  DelphiUnit in 'DelphiUnit.pas',
  LexicalAnalyser in 'LexicalAnalyser.pas',
  DelphiProject in 'DelphiProject.pas',
  ProjectSettings in 'ProjectSettings.pas',
  GexfExport in 'GexfExport.pas',
  DelphiClass in 'DelphiClass.pas';

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
