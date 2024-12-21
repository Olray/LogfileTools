unit FilterLog.CommandLine;

interface
uses
  GPCommandLineParser;

type
  TCommandLine = class
  strict private
    FSourceFileName  : string;
  public

    [CLPPosition(1), CLPDescription('File name of log file(s). Can contain wildcards'), CLPRequired]
    property SourceFileName: string read FSourceFileName write FSourceFileName;

  end;

var cl: TCommandLine;

implementation

function ParseCommandLine : TCommandLine;
begin
  Result := TCommandLine.Create;
  if not CommandLineParser.Parse(Result) then
  Begin
    for var s : String in CommandLineParser.Usage do
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
