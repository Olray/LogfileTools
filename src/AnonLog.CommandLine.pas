unit AnonLog.CommandLine;

interface
uses
  GPCommandLineParser;

type
  TCommandLine = class
  strict private
    FSourceFileName  : string;
    FDestFileName    : string;

  public
    [CLPPosition(1), CLPDescription('File name of source log file'), CLPRequired]
    property SourceFileName: string read FSourceFileName write FSourceFileName;

    [CLPPosition(2), CLPDescription('File name of destination log file'), CLPRequired]
    property DestFileName: string read FDestFileName write FDestFileName;

  end;

var cl: TCommandLine;

implementation

function ParseCommandLine : TCommandLine;
begin
  Result := TCommandLine.Create;
  if not CommandLineParser.Parse(Result) then
  begin
    for var s : String in CommandLineParser.Usage do
      Writeln(s);
    WriteLn('Press Return...');
    ReadLn;
    Halt;
  end;
end;

initialization
  cl := ParseCommandLine;

finalization
  cl.Free;

end.
