program SortLog;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinAPI.Windows,
  System.Classes,
  System.SysUtils,
  System.DateUtils,
    // install into externals from https://github.com/Olray/DeCAL
  DeCAL,
  LogToolsUnit in 'LogToolsUnit.pas';

type TFileEntry = class
                    FileName : string;
                    min      : TDateTime;
                    max      : TDateTime;
                    lines    : Integer;
                  end;

{-----------------------------------------------------------------------------
  Procedure: LinePresent
  Arguments: ALine : String; Entry : DArray
  Result:    Boolean

  Purpose:   Determines whether a string is already in a DArray. If the strings
             have a different length, only the shorter of the two parts is
             compared.
-----------------------------------------------------------------------------}
Function LinePresent(ALine : String; Entry : DArray) : Boolean;

  function Min(Value1, Value2: Integer): Integer;
  begin
    if Value1 < Value2 then
      Result := Value1
    else
      Result := Value2;
  end;

var iter  : DIterator;
    ELine : String;
    done  : Boolean;
    lenS,
    lenD,
    len   : Integer;
begin
  Result := False;
  if (Entry.size = 0) then
    Exit;

  done := False;
  lenD := Length(ALine);
  iter := Entry.start;
  while not done and not atEnd(iter) do
  begin
    ELine := getString(iter);
    lenS := Length(ELine);
    if lenS <> lenD then // If unequal length, only compare the smaller part
    begin
      len := Min(lenS, LenD);
      if Copy(ELine,1,len) = Copy(ALine,1,len) then
      begin
        Result := True;
        done := True;
      end;
    end
    else // If same length, do not use Copy() -> faster
    begin
      if ELine = ALine then
      begin
        Result := True;
        done := True;
      end;
    end;
    advance(Iter);
  end;

end;

{-----------------------------------------------------------------------------
  Procedure: IsYearMonth
  Arguments: Year, Month : WORD; DateString : AnsiString
  Result:    Boolean

  Purpose:   Checks if a DateString is in a given year and month
-----------------------------------------------------------------------------}
function IsYearMonth (Year, Month : WORD; DateString : AnsiString) : Boolean;
Begin
  Result := (Month = CalcMonth(DateString)) and
            (Year = StrToInt(Copy(DateString,8,4)));
End;

{-----------------------------------------------------------------------------
  Procedure: ReportF
  Arguments: Filename : String; lines : Cardinal; mindate, maxdate : TDateTime
  Result:    None

  Purpose:   Prints a status report of the current progress
-----------------------------------------------------------------------------}
procedure ReportF(Filename : String; lines : Cardinal; mindate, maxdate : TDateTime);
var s1,
    s2         : string;
begin
  if (mindate > 0.01) then
    s1 := FormatDateTime('dd.mm.yyyy', mindate)
  else
    s1 := '  .  .    ';

  if (maxdate > 0.01) then
    s2 := FormatDateTime('dd.mm.yyyy', maxdate)
  else
    s2 := '  .  .    ';
  Write(Format('%-20s     %8d  %s  %s'#13, [Filename, lines, s1, s2]));
End;

 {-----------------------------------------------------------------------------
  Procedure: CreateFileEntry
  Arguments: FileName : String
  Result:    DFileEntry

  Purpose:   Reads a logfile, finds out min and max date and returns a
             DFileEntry structure
-----------------------------------------------------------------------------}
function CreateFileEntry(FileName : string) : TFileEntry;
var BufO   : TFileEntry;
    Source : TStreamReader;
    BufD   : TDateTime;
    Line   : string;
    actZeile: Integer;
begin
  BufO := TFileEntry.Create;
  BufO.FileName := FileName;
  BufO.min := MaxDateTime;
  BufO.max := MinDateTime;
  BufO.lines := 0;

  Source := TStreamReader.Create(FileName, TEncoding.UTF8);

  actZeile := 0;
  while not Source.EndOfStream do
  begin
    Line := Source.ReadLine;
    Inc (actZeile);
    BufD := MakeDate(GetDatePart(Line));
    if BufD > 0.001 then
    begin
      if BufO.min > BufD then BufO.min := BufD;
      if BufO.max < BufD then BufO.max := BufD;
    end;
    Inc (BufO.lines);
    if (actZeile mod 1000 = 0) then
      ReportF(FileName, actZeile, BufO.min, BufO.max);
  End;

  CloseFileStream(Source);
  ReportF(FileName, actZeile, BufO.min, BufO.max);
  WriteLn;

  Result := BufO;
End;

{-----------------------------------------------------------------------------
  Procedure: ReadDir
  Arguments: ADir, Maske : String; VAR Dateien : DArray
  Result:    None

  Purpose:   Reads a directory and creates a list of all logfiles matching
             a given mask. Returns a list of DFileEntry in the DArray.
             Since this procedure takes some time I have rewritten it from
             LogToolsUnit.ReadDir to be some more talkative
-----------------------------------------------------------------------------}
procedure ReadDir (ADir, Maske : string; Dateien : DArray);
var SR        : TSearchRec;
    ThisFName : string;
Begin
  WriteLn('Creating Inventory...');
  WriteLn;
  WriteLn('Filename                    Lines  MinDate     MaxDate');
  WriteLn('============================================================');
  if (FindFirst (IncludeTrailingPathDelimiter(ADir)+Maske, faAnyFile, SR) = 0) Then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
          // Remove the first ./ to get relative names
        ThisFName := IncludeTrailingPathDelimiter(ADir)+SR.Name;
        ThisFName := Copy (ThisFName,3,Length(ThisFName)-2);

        if (SR.Attr and faDirectory <> faDirectory) then
        begin
          ReportF(SR.Name, 0, 0.0, 0.0);
          Dateien.Add([CreateFileEntry(ThisFName)]);
        end;
      end;
    until FindNext(SR) <> 0;
  end;
  FindClose(SR);
end;

{-----------------------------------------------------------------------------
  Procedure: Main

  Purpose:   Find all files, read them line by line and creates logfiles
             in order of DateTime sorted by month.
-----------------------------------------------------------------------------}
procedure Main;
var actZeile : Integer;
    AList    : DArray;
    DDaten   : DMap;
    CurFile  : TFileEntry;
    di       : DIterator;
    ds       : DIterator; // for searching
    Source   : TStreamReader;
    Dest     : TUnixStreamWriter;
    it       : Integer;
    BufS     : AnsiString;
    BufD     : TDateTime;
    curYear  : WORD;
    curMonth : WORD;
    endYear  : WORD;
    endMonth : WORD;
    monthMin : TDateTime;
    monthMax : TDateTime;
    totalMin : TDateTime;
    totalMax : TDateTime;
    Dummy    : WORD;
    Zeilen   : DArray;
    iter     : DIterator;
Begin
  PrintWelcome ('%FN reads an unlimited number of logfiles reads them line '+
                'by line, sorts lines by time while eliminating doubles, '+
                'finally writes the files month by month using Windows line '+
                'breaks.');
  WriteLn;
  OEMPrint('Input : All files starting with ''access'' from the current directory');
  OEMPrint('Output: Files of format access.YYYY.MM.log');
  WriteLn;
  WriteLn;

    // read list of logfiles
  AList := DArray.Create;
  ReadDir('.', 'access*.*', AList);

    // find smallest and largest year and month
  di := AList.start;
  totalMin := MaxDateTime;
  totalMax := MinDateTime;
  while iterateOver(di) Do
  begin
    CurFile := getObject(di) as TFileEntry;
    if CurFile.min < totalMin then
      totalMin := CurFile.min;
    if CurFile.max > totalMax then
      totalMax := CurFile.max;
  end;
  DecodeDateTime(totalMin, curYear, curMonth, Dummy, Dummy, Dummy, Dummy, Dummy);
  DecodeDateTime(totalMax, endYear, endMonth, Dummy, Dummy, Dummy, Dummy, Dummy);

  WriteLn; WriteLn;
  WriteLn('Sorting and separating data by months...'); WriteLn;
  WriteLn('Month    Filename                 Lines');
  WriteLn('=======================================');

  while (curYear*100+curMonth <= endYear*100+endMonth) do
  begin
    DDaten := DMap.Create;

      // iterate source files
    di := AList.start;
    actZeile := 0;
    while iterateOver(di) do
    begin
      monthMin := StartOfTheMonth(EncodeDateTime(curYear, curMonth, 1, 1, 0, 0, 0));
      monthMax := EndOfTheMonth(EncodeDateTime(curYear, curMonth, 1, 1, 0, 0, 0));

      CurFile := getObject(di) as TFileEntry;

      if not( (CurFile.max < monthMin) or (CurFile.min > monthMax) ) then
      begin
        Source := TStreamReader.Create(CurFile.FileName, TEncoding.UTF8);
        Write(Format('%2.2d.%4.4d  %-20s'#13, [curMonth, curYear, CurFile.FileName]));

        while not Source.EndOfStream Do
        begin
          BufS := Source.ReadLine;
          Inc(actZeile);

          BufD := MakeDate(GetDatepart(BufS));
          if (BufD > 0.01) and (BufD >= monthMin) and (BufD <= monthMax) then
          begin
            ds := DDaten.locate([BufD]); // O(log n)
            if atEnd(ds) then // new line
            begin
              Zeilen := DArray.Create;
              Zeilen.add([BufS]);
              DDaten.putPair([BufD, Zeilen]);
            end
            else
            begin // append line
              Zeilen := getObject(ds) as DArray;
              if not LinePresent(BufS, Zeilen) then
                Zeilen.add([BufS]);
            end;
          end; // If in the month

          if (actZeile mod 1000 = 0) Then
            Write(Format('%2.2d.%4.4d  %-20s      '#13, [curMonth, curYear, CurFile.FileName+':'+IntToStr(actZeile DIV 1000)]));

        end; // processing single line

        CloseFileStream(Source);
      end; // If File is relevant
    end; // iterating source files

    if DDaten.size > 0 then
    begin
      BufS := Format('access.%4.1d.%2.2d.log', [curYear, curMonth]);
      Dest := TUnixStreamWriter.Create(BufS, False, TEncoding.UTF8);

      di := DDaten.start;
      it := 0;
      while iterateOver(di) do
      begin
        Zeilen := getObject(di) as DArray;
        iter := Zeilen.start;
        while iterateOver(iter) do
        begin
          Dest.WriteLine(getString(iter));
          Inc(it);
        end;
      end;

      CloseFileStream(Dest);
      WriteLn(Format('%2.2d.%4d  %-20s  %8d'#13, [curMonth, curYear, BufS, it]));

      ObjFree(DDaten);
    End;

    Inc(curMonth);
    if curMonth > 12 then
    begin
      Inc(curYear);
      curMonth := 1;
    end;

    DDaten.Free;
  end; // Iterating months
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
