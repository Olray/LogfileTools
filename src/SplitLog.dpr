program SplitLog;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  LogToolsUnit in 'LogToolsUnit.pas',
    // install into externals from https://github.com/Olray/GpDelphiUnits
  GpCommandLineParser in '..\externals\GpDelphiUnits\src\GpCommandLineParser.pas',
  SplitLog.CommandLine in 'SplitLog.CommandLine.pas';


function GetFileNameForIndex(const Index: Integer): string;
begin
  Result := 'access.'+Format('%3.3d', [Index]);
end;

function GetStreamWriterForIndex(const Index: Integer): TUnixStreamWriter;
var NewFileName: string;
begin
  NewFileName := GetFileNameForIndex(Index);
  if FileExists(NewFileName) then
    raise Exception.Create(Format('Error: Output file already exists (%s)', [NewFileName]));
  Result := TUnixStreamWriter.Create(GetFileNameForIndex(Index), False, TEncoding.UTF8);
end;

function GetStreamReaderForFile(const FileName: string): TStreamReader;
begin
  if not FileExists(FileName) then
    raise Exception.Create(Format('Error: File not found (%s)', [FileName]));
  Result := TStreamReader.Create(cl.FileName, TEncoding.UTF8);
end;

function RotateStreamWriter(Writer: TStreamWriter; NewIndex: Integer): TUnixStreamWriter;
begin
  Writer.Flush;
  Writer.Close;
  Writer.Free;
  Result := GetStreamWriterForIndex(NewIndex);
end;

{-----------------------------------------------------------------------------
  Procedure: Main
  Purpose:   Splitting a text file into smaller files of a given number of
             lines
-----------------------------------------------------------------------------}
procedure Main;
var Source   : TStreamReader;
    Dest     : TUnixStreamWriter;
    BufS     : string;
    i        : Integer;
    FileNum  : Integer;
begin
  WriteLn;
  PrintWelcome('%FN splits a text file into separate files of any given '+
               'number of lines (default 10000). The output files always have '+
               'the form: access.### with ''###'' starting at 001.');

  Source := GetStreamReaderForFile(cl.FileName);

  FileNum := 1;
  Dest := GetStreamWriterForIndex(FileNum);

  i := 0;
  while not Source.EndOfStream Do
  begin
    if i >= cl.Lines Then
    begin
      Dest := RotateStreamWriter(Dest, FileNum + 1);
      Inc(FileNum);
      i := 0;
    end;
    BufS := Source.ReadLine;
    Dest.WriteLine(BufS);
    Inc(i);
  end;

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
