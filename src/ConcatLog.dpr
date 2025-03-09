program ConcatLog;

{$APPTYPE CONSOLE}

uses
  WinAPI.Windows,
  System.Classes,
  System.SysUtils,
    // install into externals from https://github.com/Olray/DeCAL
  DeCAL,
    // install into externals from https://github.com/Olray/GpDelphiUnits
  GpCommandLineParser in '..\externals\GpDelphiUnits\src\GpCommandLineParser.pas',
  LogToolsUnit in 'LogToolsUnit.pas',
  ConcatLog.CommandLine in 'ConcatLog.CommandLine.pas';

function GetStreamReaderForFile(const FileName: string): TStreamReader;
begin
  if not FileExists(FileName) then
    raise Exception.Create(Format('Error: File not found (%s)', [FileName]));
  Result := TStreamReader.Create(FileName, TEncoding.UTF8);
end;

procedure ReportFileAndLine(const FileName: string; const LineNo: Integer);
begin
  Write (Format('File: %s Line: %d        '#13, [FileName, LineNo]));
end;

{-----------------------------------------------------------------------------
  procedure: Main
  Purpose:   Concatenation of several text files given by wildcarded file name
             into one large file
-----------------------------------------------------------------------------}
procedure Main;
var AList  : DList;
    Iter   : DIterator;
    BufS   : string;
    i      : Integer;
    Source : TStreamReader;
    Dest   : TUnixStreamWriter;
Begin
  WriteLn;
  PrintWelcome('%FN concatenates an unlimited number of text files to '+
               'one single file. It processes all files in alphabetical '+
               'order by reading all files line by line and writing it '+
               'to a target file using Unix line breaks.');

  if FileExists(cl.DestFileName) then
  begin
    OEMPrint('Output file '+cl.DestFileName+' already exists. Please remove this file.');
    Exit;
  end;

  AList := GetFileList(cl.SourceFileName);

  Dest := TUnixStreamWriter.Create(cl.DestFileName, False, TEncoding.UTF8);

    // Iterate source files and copy lines to destination
  Iter := AList.start;
  while IterateOver(Iter) Do
  begin
    ReportFileAndLine(getString(Iter), 0);
    Source := TStreamReader.Create(getString(Iter), TEncoding.UTF8);
    i := 0;
    while not Source.EndOfStream do
    begin
      BufS := Source.ReadLine;
      Dest.WriteLine(BufS);
      Inc(i);
      if i MOD 1000 = 0 Then
        ReportFileAndLine(getString(Iter), i);
    end;
    Source.Free;

    Dest.Flush;
    ReportFileAndLine(getString(Iter), i); WriteLn;
  end;

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
