program ReverseRename;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  DeCAL,
  LogToolsUnit in 'LogToolsUnit.pas',
    // install into externals from https://github.com/Olray/GpDelphiUnits
  GpCommandLineParser in '..\externals\GpDelphiUnits\src\GpCommandLineParser.pas',
  ReverseRename.CommandLine in 'ReverseRename.CommandLine.pas';

const FilePrefix = 'file';

{-----------------------------------------------------------------------------
  Procedure: ReduceToNumber
  Arguments: AString : String
  Result:    String

  Reducing a string to a numeric component by removing all non-numerical chars
-----------------------------------------------------------------------------}
function ReduceToNumber(AString : string): string;
var i : Integer;
begin
  Result := '';
  for i := 1 to Length(AString) do
    if (AString[i] >= '0') and (AString[i] <= '9') then
      Result := Result + AString[i];
end;

{-----------------------------------------------------------------------------
  Procedure: Main

  Renaming files conatining numbers in reverse order
-----------------------------------------------------------------------------}
procedure Main;
var AList   : DList;
    DSorted : DMap;
    di      : DIterator;
    sNumber : string;
    nNumber : Integer;
    cNumber : Integer;
    FCount: Integer;
begin
  PrintWelcome ('%FN accepts a file mask of a set of files containing numbers. '+
                'These files are read and renamed in reverse order of their '+
                'numbers in preparation of UNIX style archived logfiles for '+
                'use with LogTool ConcatLog.');
  WriteLn;
  OEMPrint('Input : All files matching a file mask. Files MUST contain a numeric '+
           'value. No directories are allowed.');
  OEMPrint('Output: None, files are renamed to "file.NNN" on hard disk.');
  WriteLn;
  WriteLn;

    // Search log files and create + sort file list
  AList := GetFileList(cl.SourceFileName);
  DSorted := DMap.Create;

    // Iterate source files
  di := AList.start;
  while iterateOver(di) do
  begin
      // extract numbers from file name
    sNumber := ReduceToNumber(getString(di));

    if sNumber = '' then
      raise Exception.Create(Format(
            'File name %s does not contain a number. Please rename this file'+
            'prior to using this application.', 
            [getString(di)]))
    else
      nNumber := StrToInt(sNumber);

    DSorted.putPair([nNumber, getString(di)]);
  end;
  AList.Free;

    // Output debug list of files
  di := DSorted.start;
  FCount := DSorted.size + 1;
  WriteLn;
  while iterateOver(di) Do
  begin
    SetToKey(di); nNumber := FCount - getInteger(di);
    SetToValue(di); sNumber := getString(di);
    OEMPrint(Format('%.3d  %s', [nNumber, sNumber]));
  end;
  WriteLn; WriteLn;

  if not cl.Yes then
  begin
    OEMPrint('Is the above order of files correct? (Y/N)');
    ReadLn(sNumber);
    sNumber := Trim(sNumber);
  end
  else
    sNumber := 'y';
  
  cNumber := DSorted.size;
  if (sNumber='y') or (sNumber='Y') then
  begin
    di := DSorted.start;
    while iterateOver(di) do
    begin
      SetToKey(di); nNumber := getInteger(di);
      SetToValue(di); sNumber := getString(di);
      var NewFileName := Format('%s.%.3d',[FilePrefix, cNumber]);
      RenameFile(sNumber, NewFileName);
      OEMPrint(Format('Renaming "%s" to "%s"', [sNumber, NewFileName]));
      Dec(cNumber);
    end;

  end;
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
