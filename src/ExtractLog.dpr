program ExtractLog;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  LogToolsUnit in 'LogToolsUnit.pas',
  ExtractLog.CommandLine in 'ExtractLog.CommandLine.pas',
  GpCommandLineParser in '..\externals\GpDelphiUnits\src\GpCommandLineParser.pas';

function ParseDate (ADate : string) : TDateTime;
VAR D,M,Y,H,I : Integer;
Begin
  ADate := Trim(ADate);
  if TryStrToInt(Copy(ADate,1,4), Y) and
     TryStrToInt(Copy(ADate,6,2), M) and
     TryStrToInt(Copy(ADate,9,2), D) then
  begin
    if not TryEncodeDate(Y, M, D, Result) then
    begin
      OEMPrint(ADate + ' is invalid.');
      Result := 0.0;
    end
    else
    begin
      if Length(ADate) >= 16 Then // Time included
      begin
        if TryStrToInt(Copy(ADate,12,2), H) AND
           TryStrToInt(Copy(ADate,15,2), I) Then
          Result := Result + EncodeTime(H, I, 0, 0)
        else
          Result := 0.0;
      end;
    end
  end
  else
  begin
    WriteLn(ADate + ' is not a valid date.');
    Result := 0.0;
  end;
end;

procedure Main;
VAR Date1       : TDateTime;
VAR Date2       : TDateTime;
// Date calculations
VAR OneMin      : TDateTime;
VAR ts          : Cardinal;
VAR Source      : TStreamReader;
VAR Zeile       : string;
VAR UseDate     : Boolean;
Begin
  if not cl.Quiet then
  begin
    PrintWelcome ('%FN extracts a set of lines from apache logfiles matching '+
                  'a time and IP/hostname address and sends them to stdout.');
    WriteLn;
    WriteLn('Hostname: '+cl.HostName);
  end;

  UseDate := False;
  if (cl.From <> '') and (cl.ToS <> '') then
  begin
    Date1 := ParseDate(cl.From);
    Date2 := ParseDate(cl.ToS);
    UseDate := True;
  end
  else if (cl.around <> '') and (cl.Minutes = 0) then
  Begin
    ts := cl.Minutes;
    OneMin := EncodeTime(ts div 60, ts mod 60, 0, 0);
    Date1 := ParseDate(cl.Around);
    Date2 := Date1 + OneMin;
    Date1 := Date1 - OneMin;
    UseDate := True;
  End;

  if Date1 > Date2 Then
  begin
    var TempT := Date1;
    Date1 := Date2;
    Date2 := TempT;
  end;

  if UseDate and not cl.Quiet then
  begin
    OEMPrint('Using date-time range:');
    OEMPrint('From    : '+DateTimeToStr(Date1));
    OEMPrint('To      : '+DateTimeToStr(Date2));
  end;

  Source := TStreamReader.Create(cl.SourceFileName, TEncoding.UTF8);

  while not Source.EndOfStream Do
  begin
    Zeile := Source.ReadLine;

    if (GetHostnamePart(Zeile) = cl.HostName) then
    begin
      if UseDate Then
      begin
        var TempT := MakeDate(GetDatepart(Zeile));
        if (TempT > 0) and (TempT >= Date1) and (TempT <= Date2) then
          WriteLn(Zeile);
      end
      else
        WriteLn(Zeile);
    end;

  end;

  CloseFileStream(Source);
end;

begin
  try
    Main;
  except
    on E: Exception do
      WriteLn('Error: '+E.Message);
  end;
end.
