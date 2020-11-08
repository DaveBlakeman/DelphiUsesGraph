unit LexicalAnalyserTests;

interface
uses
  DUnitX.TestFramework,
  LexicalAnalyser;

type

  [TestFixture]
  TLexicalAnalyserTests = class
  private
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    [TestCase('Empty', ', True')]
    [TestCase('Non-empty', 'X, False')]
    procedure TestEOF(const InputString : String; const ExpectedResult: Boolean);

    [Test]
    [TestCase('Number: Simple Integer', '1,1')]
    [TestCase('Number: Simple Integer And Other', '1 X,1')]
    [TestCase('Number: Double Digit', '12,12')]
    [TestCase('Number: Decimal', '12.1 X,12.1')]
    [TestCase('Number: DoubleDecimal', '12.21 X,12.21')]
    [TestCase('Number: Hex', '$12 X,$12')]
    procedure TestNumbers(const InputString : String; const ExpectedResult: String);

    [Test]
    [TestCase('Whitespace: Simple Space', 'A B,A,B')]
    [TestCase('Whitespace: Tab Between Chars', 'A'#9'B,A,B')]
    [TestCase('Whitespace: NewLine', 'A'#13#10'B,A,B')]
    procedure TestWhitespace(const InputString : String; const FirstString, SecondString: String);

    [Test]
    [TestCase('Comment: Traditional ', 'A (*comment*) B,A,B')]
    [TestCase('Comment: Traditional non-terminated', 'A (*comment,A,'#0)]
    [TestCase('Comment: Traditional compact', 'A(*comment*)B,A,B')]
    [TestCase('Comment: Multi-line traditional', 'A (*A comment'#13#10'another line'#13#10'*) B,A,B')]
    [TestCase('Comment: Brace', 'A {comment} B,A,B')]
    [TestCase('Comment: Brace compact', 'A{comment}B,A,B')]
    [TestCase('Comment: Multi-line brace', 'A{A comment'#13#10'another line'#13#10'}B,A,B')]
    [TestCase('Comment: Brace within traditional', 'A (* {A comment} *) B,A,B')]
    [TestCase('Comment: Traditional within brace', 'A {(* A comment *) } B,A,B')]
    [TestCase('Comment: Single line', 'A// A comment'#13#10'B,A,B')]
    procedure TestComments(const InputString : String; const FirstString, SecondString: String);

    [Test]
    [TestCase('Identifier: Single character', 'A B,A,B')]
    [TestCase('Identifier: Starts with underscore', '_A B,_A,B')]
    [TestCase('Identifier: Ends with underscore', 'A_ B,A_,B')]
    [TestCase('Identifier: Contains digits and underscores', 'A_123 B,A_123,B')]
    procedure TestIdentifier(const InputString : String; const FirstString, SecondString: String);

    [Test]
    [TestCase('Unary: -ve identifier', '-A,-,A')]
    [TestCase('Unary: +ve identifier', '+A,+,A')]
    [TestCase('Unary: not identifier', 'not A,not,A')]
    procedure TestUnary(const InputString : String; const Op, Operand: String);

    [Test]
    [TestCase('Binary: add', 'A+B,A,+,B')]
    [TestCase('Binary: subtract', 'A-B,A,-,B')]
    [TestCase('Binary: multiply', 'A*B,A,*,B')]
    [TestCase('Binary: divide', 'A/B,A,/,B')]
    [TestCase('Binary: div', 'A div B,A,div,B')]
    [TestCase('Binary: mod', 'A mod B,A,mod,B')]
    [TestCase('Binary: equal', 'A = B,A,=,B')]
    [TestCase('Binary: not equal', 'A <> B,A,<>,B')]
    [TestCase('Binary: less', 'A < B,A,<,B')]
    [TestCase('Binary: less equal', 'A <= B,A,<=,B')]
    [TestCase('Binary: greater', 'A > B,A,>,B')]
    [TestCase('Binary: greater equal', 'A >= B,A,>=,B')]
    [TestCase('Binary: range', 'A..B,A,..,B')]
    procedure TestBinary(const InputString : String; const Operand1, Op, Operand2: String);

    [Test]
    [TestCase('Parenthesis: simple', '(A),(,A,)')]
    [TestCase('Parenthesis: array', '[A],[,A,]')]
    procedure TestParenthesis(const InputString : String; const Open, Content, Close: String);

  end;

implementation

uses
  SysUtils;

procedure TLexicalAnalyserTests.Setup;
begin
end;

procedure TLexicalAnalyserTests.TearDown;
begin

end;

procedure TLexicalAnalyserTests.TestBinary(const InputString, Operand1, Op, Operand2: String);
var
  Lex: TLexicalAnalyser;
  Operand1Sym: String;
  OperatorSym: String;
  Operand2Sym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    Operand1Sym := Lex.CurrentSym;
    OperatorSym := Lex.GetSym;
    Operand2Sym := Lex.GetSym;
    Assert.AreEqual(Operand1Sym, Operand1);
    Assert.AreEqual(OperatorSym, Op);
    Assert.AreEqual(Operand2Sym, Operand2);
  finally
    FreeAndNil(Lex);
  end;
end;

procedure TLexicalAnalyserTests.TestComments(const InputString, FirstString, SecondString: String);
var
  Lex: TLexicalAnalyser;
  FirstSym: String;
  SecondSym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    FirstSym := Lex.CurrentSym;
    SecondSym := Lex.GetSym;
    Assert.AreEqual(FirstSym, FirstString);
    Assert.AreEqual(SecondSym, SecondString);
  finally
    FreeAndNil(Lex);
  end;
end;

procedure TLexicalAnalyserTests.TestEOF(const InputString: String; const ExpectedResult: Boolean);
var
  Lex: TLexicalAnalyser;
begin
  try
    Lex:=TLexicalAnalyser.CreateFromString(InputString);
    try
      Assert.AreEqual(Lex.AtEnd, ExpectedResult);
    finally
      FreeAndNil(Lex);
    end;
  except
    on E: Exception do

  end;
end;


procedure TLexicalAnalyserTests.TestIdentifier(const InputString, FirstString, SecondString: String);
var
  Lex: TLexicalAnalyser;
  FirstSym: String;
  SecondSym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    FirstSym := Lex.CurrentSym;
    SecondSym := Lex.GetSym;
    Assert.AreEqual(FirstSym, FirstString);
    Assert.AreEqual(SecondSym, SecondString);
  finally
    FreeAndNil(Lex);
  end;
end;

procedure TLexicalAnalyserTests.TestNumbers(const InputString, ExpectedResult: String);
var
  Lex: TLexicalAnalyser;
  Sym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    Sym := Lex.CurrentSym;
    Assert.AreEqual(Sym, ExpectedResult);
  finally
    FreeAndNil(Lex);
  end;
end;

procedure TLexicalAnalyserTests.TestParenthesis(const InputString, Open, Content, Close: String);
var
  Lex: TLexicalAnalyser;
  OpenSym: String;
  ContentSym: String;
  CloseSym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    OpenSym := Lex.CurrentSym;
    ContentSym := Lex.GetSym;
    CloseSym := Lex.GetSym;
    Assert.AreEqual(OpenSym, Open);
    Assert.AreEqual(ContentSym, Content);
    Assert.AreEqual(CloseSym, Close);
  finally
    FreeAndNil(Lex);
  end;
end;

procedure TLexicalAnalyserTests.TestUnary(const InputString, Op, Operand: String);
var
  Lex: TLexicalAnalyser;
  FirstSym: String;
  SecondSym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    FirstSym := Lex.CurrentSym;
    SecondSym := Lex.GetSym;
    Assert.AreEqual(FirstSym, Op);
    Assert.AreEqual(SecondSym, Operand);
  finally
    FreeAndNil(Lex);
  end;
end;

procedure TLexicalAnalyserTests.TestWhitespace(const InputString, FirstString, SecondString: String);
var
  Lex: TLexicalAnalyser;
  FirstSym: String;
  SecondSym: String;
begin
  Lex:=TLexicalAnalyser.CreateFromString(InputString);
  try
    FirstSym := Lex.CurrentSym;
    SecondSym := Lex.GetSym;
    Assert.AreEqual(FirstSym, FirstString);
    Assert.AreEqual(SecondSym, SecondString);
  finally
    FreeAndNil(Lex);
  end;
end;


initialization
  TDUnitX.RegisterTestFixture(TLexicalAnalyserTests);
end.
