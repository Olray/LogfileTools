unit ReverseRename.CommandLine;

interface
uses
  GPCommandLineParser;

type
  TCommandLine = class
  strict private
    FSourceFileName: string;
    FYes: Boolean;
  public
    [CLPPosition(1), CLPDescription('File mask with place holder of files to process'), CLPRequired]
    property SourceFileName: string read FSourceFileName write FSourceFileName;

    [CLPName('y'),
     CLPLongName('yes'),
     CLPDescription('Do not ask any questions, assume Yes for everything')]
    property Yes: Boolean read FYes write FYes;
  end;

var cl: TCommandLine;

implementation

function ParseCommandLine : TCommandLine;
begin
  Result := TCommandLine.Create;
  if not CommandLineParser.Parse(Result) then
  Begin
    for var s : string in CommandLineParser.Usage do
      Writeln(s);
    WriteLn('Press Return...');
    ReadLn;
    Halt;
  End;
end;

initialization
  cl := ParseCommandLine;

finalization
  cl.Free;

end.
