program Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  Vcl.Forms,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.Loggers.GUIVCL,
  DUnitX.TestRunner,
  DUnitX.TestFramework,
  LexicalAnalyserTests in 'LexicalAnalyserTests.pas',
  LexicalAnalyser in '..\LexicalAnalyser.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
   Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
end.
