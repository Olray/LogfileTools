program AnonLog;

{$APPTYPE CONSOLE}

uses
  Windows,
  Classes,
  SysUtils,
  Hash,
  DeCAL,
  LogToolsUnit in 'C:\Delphi\LogTools\LogToolsUnit.pas',
  AnonLog.CommandLine in 'AnonLog.CommandLine.pas',
    // install into externals from https://github.com/Olray/GpDelphiUnits
  GpCommandLineParser in '..\externals\GpDelphiUnits\src\GpCommandLineParser.pas';

function AnonymizeLine(ALine : string) : string;

  function StripAfterSecondQuote(const ALine: string): string;
  var i: Integer;
  begin
    i := Pos('"', ALine);
    if i > 0 then
      i := Pos('"', ALine, i+1);
    Result := Copy(ALine, 1, i);
  end;

var MD5       : THashMD5;
    IpAddr    : string;
    tempi     : Integer;
//    targetlen : Integer;
begin
    // strip browser information
  Result := StripAfterSecondQuote(ALine);
    // extract IP
  tempi := Pos(' ', Result);
  IpAddr := Copy(Result, 1, tempi-1);
  if tempi > 0 then
  begin
    MD5.Reset;
    MD5.Update(IpAddr[1], Length(IpAddr));
    Result := Copy(MD5.HashAsString, 1, 8) + ' ' + Copy(ALine, tempi+1, Length(Result)-tempi);
  end;
end;

procedure ReportFileAndLine(const FileName: string; const LineNo: Integer);
begin
  Write (Format('File: %s Line: %d        '#13, [FileName, LineNo]));
end;

{-----------------------------------------------------------------------------
  Procedure: Main
  Purpose:   Anonymizing a log file by replacing IP addresses with hashes
-----------------------------------------------------------------------------}
procedure Main;
var BufS     : String;
    i        : Integer;
    Source   : TStreamReader;
    Dest     : TStreamWriter;
begin
  WriteLn;
  PrintWelcome('%FN anonymizes a logfile by replacing all IP addresses with '+
               'a hash value');

    // check files
  if FileExists(cl.DestFileName) Then
  begin
    OEMPrint(Format('Output file ''%s'' already exists.', [cl.DestFileName]));
    Exit;
  end;
  if not FileExists(cl.SourceFileName) Then
  begin
    OEMPrint(Format('Input file ''%s'' not found.', [cl.SourceFileName]));
    Exit;
  end;

  Source := TStreamReader.Create(cl.SourceFileName, TEncoding.UTF8);
  Dest := TUnixStreamWriter.Create(cl.DestFileName, False, TEncoding.UTF8);

  i := 0;
  while not Source.EndOfStream do
  begin
    BufS := AnonymizeLine(Source.ReadLine);
    Dest.WriteLine(BufS);
    Inc(i);
    if i mod 1000 = 0 then
      ReportFileAndLine(cl.SourceFileName, i);
  end;
  ReportFileAndLine(cl.SourceFileName, i);

  CloseFileStream(Source);
  CloseFileStream(Dest);
end;

begin
  try
    Main;
  except
    on E: Exception do
      WriteLn('Error: '+E.Message);
  end;
end.
