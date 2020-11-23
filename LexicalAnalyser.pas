unit LexicalAnalyser;

interface

  type

    TLogLevel = (llInfo, llWarning, llError);

    TInfoProc = procedure (S: String; Level: TLogLevel = llInfo) of object;

    TLexicalAnalyser = class
    private
      fText     : String;
      fPos      : Integer;
      fPrevPrev : String; // 2 symbols back
      fPrev     : String; // 1 symbols back
      fSym      : string;
      fCh       : Char;
      fLineNo   : Integer;
      fLogging  : Boolean;
      fFileName : String;
      fLogProc  : TInfoProc;
      procedure GetCh;
      procedure GetASym;
      procedure ShowError(S: String);
      function TextBetween(Start: Integer; Finish: Integer): String;
      function LineStart: Integer;
      function LineEnd: Integer;
      procedure Log(S: String; Level: TLogLevel = llInfo);
    public
      constructor CreateFromFile(FileName: String);
      constructor CreateFromString(S: String);

      function  CurrentSym: String;
      function  PreviousSym(SymbolsAgo: Integer): String;
      function  GetSym: String;

      function  AtEnd: Boolean;

      function  SymbolIs(S: String): Boolean;
      procedure RequiredSym(S: String);
      function  OptionalSym(S: String): Boolean;
      procedure SkipToEof;

      procedure SkipTo(S: String);

      property Logging: Boolean read fLogging write fLogging;
      property LineNo: Integer read fLineNo;
      property LogProc: TInfoProc   read fLogProc write fLogProc;
    end;

implementation

uses
  IOUtils,
  SysUtils;

const
  cLetters   = ['a'..'z', 'A'..'Z'];
  cDigits    = ['0'..'9'];
  cNumStarts = cDigits + ['-', '$'];
  cNumChars  = cDigits + ['.', '-', '#', 'E'];
  cHexChars  = cDigits + ['a'..'f', 'A'..'F'];
  cIdStarts  = cLetters + ['_'];
  cIdChars   = cLetters + cDigits + ['_'];

  
{ TLexicalAnalyser }

constructor TLexicalAnalyser.CreateFromFile(FileName: String);
begin
  fText:='';
  fPos:=1;
  fSym:='';
  fLogging:=False;
  fLineNo:=1;
  fFileName:=FileName;
  fText := TFile.ReadAllText(fFileName);
  if Length(fText) > 0 then
    fCh:=fText[1]
  else
    fCh:=#0;
  fPos:=1;
  GetSym
end;

constructor TLexicalAnalyser.CreateFromString(S: String);
begin
  fText:='';
  fPos:=1;
  fSym:='';
  fLogging:=False;
  fLineNo:=1;
  fFileName:='';
  fText := S;
  if Length(fText) > 0 then
    fCh:=fText[1]
  else
    fCh:=#0;
  GetSym
end;

function TLexicalAnalyser.CurrentSym: String;
begin
  Result:=fSym;
end;

function TLexicalAnalyser.AtEnd: Boolean;
begin
  Result:=fPos > Length(fText)
end;

procedure TLexicalAnalyser.GetCh;
  (* read the next character off the input buffer and advance the pointer *)
begin
  fPos:=fPos+1;
  fCh:=fText[fPos];
  if fCh = chr(13) then
  begin
    fLineNo:=fLineNo + 1
  end
end;

procedure TLexicalAnalyser.GetASym;

  procedure IgnoreComment;
  begin
    while (fPos < Length(fText)) and (fCh <> '}') do
      GetCh
  end;

  procedure IgnoreSingleLineComment;
  begin
    while (fPos < Length(fText)) and (fCh <> chr(13)) do
      GetCh
  end;

  procedure IgnoreTraditionalComment;
  begin
    repeat
      GetCh;
    until (fPos >= Length(fText)) or ((fCh = '*') and (fText[fPos+1] = ')'));
    GetCh;
  end;

  procedure SkipWhiteSpace;
  begin
    while (fPos <= Length(fText)) and (CharInSet(fCh, [' ', '{', chr(9), chr(10), chr(13), '/', '('])) do
    begin
      if (fCh = '/') then
      begin
        if fText[fPos+1] = '/' then
          IgnoreSingleLineComment
        else
          Exit
      end
      else if (fCh = '(') then
      begin
        if fText[fPos+1] = '*' then
          IgnoreTraditionalComment
        else
          Exit
      end
      else if fCh = '{' then
        IgnoreComment;
      GetCh
    end
  end;

  procedure GetIdentifier;
  begin
    fSym:='';
    while CharInSet(fCh, cIdChars) do
    begin
      fSym:=fSym + fCh;
      GetCh
    end
  end;

  procedure GetNumber;

    function GetHex(): String;
    begin
      Result:='$';
      repeat
        GetCh;
        if CharInSet(fCh, cHexChars) then
          Result := Result + fCh
        else
          break;
      until (fPos >= Length(fText));
    end;

    function GetDecimal(): String;
    begin
      Result:=fCh;
      while (fPos < Length(fText)) do
      begin
        GetCh;
        if CharInSet(fCh, cNumChars) and (fCh <> '#') then
          Result:=Result + fCh
        else
          break;
      end
    end;

  begin
    if fCh = '$'  then
      fSym:= GetHex()
    else
      fSym:=GetDecimal()
  end;

  procedure GetString;
    var
      Done: Boolean;
  begin          
    GetCh; // skip leading '''
    Done:=False;
    repeat
      if fCh = Chr(13) then
      begin
        ShowError('String spans more then one line');
        Exit
      end;
      if fCh <> '''' then
      begin
        fSym:=fSym + fCh;
        GetCh
      end
      else // test for double quote
        if (fPos < Length(fText)) and (fText[fPos+1] = '''') then
        begin
          fSym:=fSym+'''';
          GetCh;
          GetCh
        end
        else
          Done:=True
    until (fPos >= Length(fText)) or Done;
    GetCh; 
  end;

  procedure GetOperator;
  begin
    fSym:=fCh;
    GetCh;
    case fSym[1] of
     '<': if fCh = '=' then
          begin
            GetCh;
            fSym:='<='
          end
          else if fCh = '>' then
          begin
            GetCh;
            fSym:='<>'
          end;
     '>': if fCh = '=' then
          begin
            GetCh;
            fSym:='>='
          end;
     '.': if fCh = '.' then
          begin
            GetCh;
            fSym:='..'
          end;
     else
       // Skip
    end;
  end;

begin
  fSym:='';
  if not AtEnd then
  begin
    SkipWhiteSpace;
    if not AtEnd then
    begin
      if CharInSet(fCh, cIdStarts) then
        GetIdentifier
      else if CharInSet(fCh, cNumStarts) then
        GetNumber
      else if fCh = '''' then
        GetString
      else
        GetOperator;
    end
  end
  else
  begin
    fSym:=#0
  end;
//  if fLogging then
//    Log('Lex: ' + fSym);
end;

function TLexicalAnalyser.GetSym: String;
begin
  if fSym = #0 then
    raise Exception.Create('GetSym: EOF!!! previous was: ' + fSym);
  fPrevPrev:=fPrev;
  fPrev:=fSym;
  GetASym;
  Result:=fSym;
end;

procedure TLexicalAnalyser.RequiredSym(S: String);
begin
  if not SymbolIs(S) then
  begin
    ShowError('"' + S + '" expected, "' + fSym + '" found: ' + TextBetween(LineStart, LineEnd));
  end;
  GetSym
end;

function TLexicalAnalyser.SymbolIs(S: String): Boolean;
begin
  Result:=AnsiSameText(S, fSym)
end;

function TLexicalAnalyser.TextBetween(Start, Finish: Integer): String;
begin
  Result:=Copy(fText, Start, Finish - Start + 1)
end;

function TLexicalAnalyser.LineStart: Integer;
begin
  Result:=fPos;
  while (Result > 0) and (fText[Result] <> chr(10)) do
    Result:=Result - 1;
end;

function TLexicalAnalyser.LineEnd: Integer;
begin
  Result:=fPos;
  while (Result < Length(fText)) and (fText[Result] <> chr(13)) do
    Result:=Result + 1;
  Result:=Result-1
end;

procedure TLexicalAnalyser.Log(S: String; Level: TLogLevel);
begin
  if fLogging and Assigned(fLogProc) then
    fLogProc(IntToStr(LineNo) + ': ' + S)
end;

procedure TLexicalAnalyser.SkipTo(S: String);
begin
  while not SymbolIs(S) and not AtEnd do
    GetSym;
  GetSym;
  //Log('Found ' + S);
end;

procedure TLexicalAnalyser.SkipToEof;
begin
  while not AtEnd do
    GetSym;
end;

procedure TLexicalAnalyser.ShowError(S: String);
begin
  Log(S + ' in ' + fFileName + ' at line ' + IntToStr(fLineNo), llError);
end;

function TLexicalAnalyser.OptionalSym(S: String): Boolean;
begin
  Result:=False;
  if Self.SymbolIs(S) then
  begin
    Result:=True;
    Self.GetSym
  end
end;

function TLexicalAnalyser.PreviousSym(SymbolsAgo: Integer): String;begin
  if SymbolsAgo = 0 then
    Result:=fPrev
  else if SymbolsAgo = 1 then
    Result:=fPrevPrev
  else
    raise Exception.Create('PreviousSym: too far back!');
end;

end.