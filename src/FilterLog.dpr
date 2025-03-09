program FilterLog;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  DeCAL,
  LogToolsUnit in 'LogToolsUnit.pas',
  FilterLog.CommandLine in 'FilterLog.CommandLine.pas',
    // install into externals from https://github.com/Olray/GpDelphiUnits
  GpCommandLineParser in '..\externals\GpDelphiUnits\src\GpCommandLineParser.pas';

function EnumLogfiles(const FileNameMask: string): DList;
begin
    // enum logfiles
  Result := GetFileList(cl.SourceFileName);

  if (Result.size < 1) then
    raise Exception.Create(Format('No files matching ''%s'' found.', [FileNameMask]));
end;

function ReadFilterDat(const FileName: string): DArray;
var Quelle   : TStreamReader;
    BufS     : string;
begin
  if not FileExists(FileName) then
    raise Exception.Create(Format('Required input file ''%s'' not found', [FileName]));

  Result := DArray.Create;
  Quelle := TStreamReader.Create(FileName, TEncoding.UTF8);
  while not Quelle.EndOfStream do
  begin
    BufS := Quelle.ReadLine;
    if Trim(BufS) <> '' then
      Result.add([BufS]);
  end;
  Quelle.Free;
end;

procedure ReportFileAndLine(const FileName: string; const LineNo: Integer);
begin
  Write (Format('File: %s Line: %d        '#13, [FileName, LineNo]));
end;

procedure RenameResultFile(const FileName, TempFileName: string);
begin
  if not DeleteFile(FileName) Then
    raise Exception.Create('Cannot remove source file '+FileName+' from filesystem.');

  if not RenameFile(TempFileName, FileName) Then
    raise Exception.Create('Cannot rename temporary file to '+FileName+'.');
end;

{-----------------------------------------------------------------------------
  Procedure: Main
  Purpose:   Filter log files using strings from 'filter.dat'
-----------------------------------------------------------------------------}
procedure Main;
VAR AList    : DList;
VAR di       : DIterator;
VAR BufS     : String;
VAR i        : Integer;
VAR Source   : TStreamReader;
VAR Dest     : TUnixStreamWriter;
VAR Filters  : DArray;
VAR iter     : DIterator;
VAR Okay     : Boolean;
Begin
  WriteLn;
  PrintWelcome('%FN filters a number of files and removes all lines '+
               'containing a string listed in text file filter.dat. '+
               'overwriting the original file.');

    // read list of input file names
  AList := EnumLogfiles(cl.SourceFileName);
    // read filter strings from filter.dat
  Filters := ReadFilterDat('filter.dat');
    // iterate files and filter them line by line

  di := AList.start;
  while iterateOver(di) Do
  begin
    ReportFileAndLine(getString(di), 0);

      // open input file
    Source := TStreamReader.Create(getString(di), TEncoding.UTF8);
      // create output file
    Dest := TUnixStreamWriter.Create(getString(di)+'.tmp', False, TEncoding.UTF8);

    i := 0;
    while not Source.EndOfStream Do
    Begin
      BufS := Source.ReadLine;

      iter := Filters.start;
      Okay := True;
      while not atEnd(iter) Do
      begin
        if (Pos(getString(iter),BufS) > 0) then
        begin
          Okay := False;
          break; {while}
        end;
        advance(iter);
      end;

      if Okay then
        Dest.WriteLine(BufS);

      Inc(i);
      if i mod 1000 = 0 then
        ReportFileAndLine(getString(di), i);
    End;

    CloseFileStream(Source);
    CloseFileStream(Dest);

    ReportFileAndLine(getString(di), i);

      // Delete source and rename destination file
    RenameResultFile(getString(di), getString(di)+'.tmp');
  end;

  AList.Free;
  Filters.Free;
end;

begin
  try
    Main;
  except
    on E: Exception do
      WriteLn('Error: '+E.Message);
  end;
end.

