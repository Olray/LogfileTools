unit ExtractLog.CommandLine;

interface
uses
  GPCommandLineParser;

type
  TCommandLine = class
  strict private
    FSourceFileName  : string;
    FHostName        : string;
    FFrom            : string;
    FTo              : string;
    FAround          : string;
    FMinutes         : Integer;
    FQuiet           : Boolean;
    function Validate: string;
  public
    [CLPPosition(1), CLPDescription('File name of log file'), CLPRequired]
    property SourceFileName: string read FSourceFileName write FSourceFileName;

    [CLPName('h'),
     CLPLongName('hostname'),
     CLPDescription('Filtering for <hostname>, Required argument.'),
     CLPRequired]
    property HostName: string read FHostName write FHostName;

    [CLPName('f'),
     CLPLongName('from'),
     CLPDescription('From date/time in format: "YYYY-MM-DDTHH:MM" You cannot omit the HH:MM part.')]
    property From: string read FFrom write FFrom;

    [CLPName('t'),
     CLPLongName('to'),
     CLPDescription('To date/time in format: "YYYY-MM-DDTHH:MM" You cannot omit the HH:MM part.')]
    property ToS: string read FTo write FTo;

    [CLPName('a'),
     CLPLongName('around'),
     CLPDescription('To date/time in format: "YYYY-MM-DDTHH:MM" You cannot omit the HH:MM part.')]
    property Around: string read FAround write FAround;

    [CLPName('m'),
     CLPLongName('minutes'),
     CLPDescription('Use a time range along with the /around parameter.')]
    property Minutes: Integer read FMinutes write FMinutes;

    [CLPName('q'),
     CLPLongName('quiet'),
     CLPDescription('No extra information, just the output.')]
    property Quiet: Boolean read FQuiet write FQuiet;

    [CLPVerifier]
    property VerifyParameters: string read Validate;
  end;

var cl: TCommandLine;

implementation
uses
  System.SysUtils;

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

{ TCommandLine }

function TCommandLine.Validate: string;
begin
    // both from and to must be given
  if(From <> '') xor (ToS <> '') then
    Exit('Both --from and --to parameters are required');

    // both around and minutes must be given
  if(Around <> '') and (Minutes = 0) then
    Exit('When the around parameter is given, we also need minutes.');

    // source file must exist
  if not FileExists(SourceFileName) then
    Exit(Format('File %s not found.', [SourceFileName]));

  Result := '';
end;

initialization
  cl := ParseCommandLine;

finalization
  cl.Free;

end.
