unit SplitLog.CommandLine;

interface
uses
  System.SysUtils,
  GPCommandLineParser;

type
  TCommandLine = class
  strict private
    FFileName       : string;
    FLines          : Integer;
    function Verify: string;
  public
    [CLPPosition(1), CLPDescription('Filename of the logfile to process'), CLPRequired]
    property FileName: string read FFileName write FFileName;

    [CLPPosition(2), CLPDescription('Number of lines in each split file'), CLPDefault('10000')]
    property Lines: Integer read FLines write FLines;

    [CLPVerifier]
    property DoVerify: string read Verify;
  end;

var cl: TCommandLine;

implementation

function TCommandLine.Verify: string;
begin
  if(Lines < 1000) then
    Exit('Please allow at least 1000 lines per file or your hard disk might blow up :)');

  if not FileExists(FileName) then
    Exit('Log file not found');

  Result := '';
end;

function ParseCommandLine : TCommandLine;
begin
  Result := TCommandLine.Create;
  if not CommandLineParser.Parse(Result) then
  Begin
    for var s : String in CommandLineParser.Usage do
      Writeln(s);
    WriteLn('Error: '+CommandLineParser.ErrorInfo.Text);
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
