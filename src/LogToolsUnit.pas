unit LogToolsUnit;

interface

Uses
  System.SysUtils,
  System.Classes,
  DeCAL;

type
  TUTF8N = class(TUTF8Encoding)
  public
    function GetPreamble: TBytes; override;
  end;

  TUnixStreamWriter = class(TStreamWriter)
  strict private
    FNoBOMEncoder: TUTF8N;
  public
    constructor Create(Stream: TStream); overload;
      // TEncoding is ignored
    constructor Create(Stream: TStream; Encoding: TEncoding; BufferSize: Integer = 4096); overload;
    constructor Create(const Filename: string; Append: Boolean = False); overload;
      // TEncoding is ignored
    constructor Create(const Filename: string; Append: Boolean; Encoding: TEncoding; BufferSize: Integer = 4096); overload;
    destructor Destroy; override;
  end;

procedure OEMPrint (AString : string);
procedure PrintWelcome(WelcomeMessage : string);

function GetHostnamePart(OriginalLine : string) : string;
function GetDatePart(OriginalLine : string) : string;
function CalcMonth (DateString : string) : WORD;
function MakeDate(const DateString : string) : TDateTime;

function GetFileList(const FileNameWithPlaceholder: string): DList;
procedure CloseFileStream(const StreamObject: TStreamReader); overload;
procedure CloseFileStream(const StreamObject: TStreamWriter); overload;

implementation
uses
  WinAPI.Windows,
  System.StrUtils,
  System.DateUtils;   // TryEncodeDateTime

{-----------------------------------------------------------------------------
  procedure: OEMPrint
  Arguments: AString : string
  Result:    None

  Purpose:   Druckt Strings im OEM-Format auf der Konsole
-----------------------------------------------------------------------------}
procedure OEMPrint (AString : string);

  procedure PrintString(AString: string);
  VAR MaxLen : Integer;
  VAR BufOEM : UTF8String;
  Begin
    BufOEM := UTF8Encode(AString);
    WriteLn(BufOEM);
  End;

var BufW    : string;
    Zeile   : string;
    Done    : Boolean;
    i       : Integer;
begin
  // Zeilenumbruch
  BufW := AString;
  Done := False;
  Zeile := '';
  while not Done do
  begin
    if Length(BufW) <= 78 Then
    begin
      PrintString(Trim(BufW));
      Done := True;
    end
    else
    begin
      i := 71;
      repeat
        Dec(i);
      until (i < 1) OR (Copy(BufW, i, 1) = ' ');
      if i = 1 Then i := 70;
      PrintString(Trim(Copy(BufW, 1, i)));
      BufW := Copy(BufW, i+1, Length(BufW)-1);
    end;
  end;
end;


{-----------------------------------------------------------------------------
  procedure: PrintWelcome
  Arguments: WelcomeMessage : string
  Result:    None

  Purpose:   Druckt einen string auf der Konsole mit Zeilenumbruch bei 78
             Zeichen und der Ersetzung von $FN mit dem aktuellen Dateinamen
             (auch wenn die Datei umbenannt wurde)
-----------------------------------------------------------------------------}
procedure PrintWelcome(WelcomeMessage : string);
begin
  if Pos('%FN', WelcomeMessage) > 0 then
    WelcomeMessage := ReplaceText(WelcomeMessage, '%FN', ExtractFileName(ParamStr(0)));
  OEMPrint(WelcomeMessage);
end;


{-----------------------------------------------------------------------------
  procedure: GetHostnamePart
  Arguments: OriginalLine : string
  Result:    string

  Purpose:   Extrahiert den Hostnamen aus einer Zeile der Logdatei
-----------------------------------------------------------------------------}
function GetHostnamePart(OriginalLine : string) : string;
var i : Integer;
begin
  i := Pos(' ', OriginalLine);
  if i > 1 then
    Result := Copy(OriginalLine,1,i-1)
  else
    Result := '';
end;

{-----------------------------------------------------------------------------
  procedure: GetDatePart
  Arguments: OriginalLine : string
  Result:    string

  Purpose:   Extrahiert den Datumspart aus einer Zeile in der Logdatei
-----------------------------------------------------------------------------}
function GetDatePart(OriginalLine : string) : string;
VAR i, j : Integer;
Begin
  i := Pos('[', OriginalLine);
  j := Pos(']', OriginalLine);
  if (i>0) and (j>0) then
    Result := Copy(OriginalLine,i+1,j-i-1)
  else
    Result := '';
end;

{-----------------------------------------------------------------------------
  procedure: CalcMonth
  Arguments: DateString : string
  Result:    WORD

  Purpose:   Decodes a month from a three character representation
-----------------------------------------------------------------------------}
function CalcMonth (DateString : string) : WORD;
begin
  Result := 0;
  case DateString[4] of
    'A':   begin { April, August }
             if (DateString[5] = 'p') then
               Result := 4
             else
               Result := 8;
           end;
    'D':   Result := 12; { December }
    'F':   Result := 2; { February }
    'J':   begin { January, June, July }
             if (DateString[5] = 'a') then
               Result := 1
             else if (DateString[6] = 'n') then
               Result := 6
             else
               Result := 7;
           end;
    'M':   begin { March/May }
             if(DateString[6] = 'y') then
               Result := 5
             else
               Result := 3;
           end;
    'N':   Result := 11; { November }
    'O':   Result := 10; { October }
    'S':   Result := 9; { September }
    else
    begin
      PrintWelcome ('Cannot calculate month in string '''+ DateString +''' '+
                    'The source file might have been damaged due to a hacking '+
                    'attempt. The suggestion is to use SplitLog to split '+
                    'up the log in editable parts and delete the defective '+
                    'line in question. Good luck!');
      Halt;
    end;
  end;
end;


{-----------------------------------------------------------------------------
  procedure: MakeDate
  Arguments: DateString : string
  Result:    TDateTime

  Purpose:   Changes a DateString from an Apache logfile to a TDateTime
-----------------------------------------------------------------------------}
function MakeDate(const DateString : string) : TDateTime;
var day, month, year : WORD;
    hour, minute, second : WORD;
const null = ord('0');
begin
  if (Length(DateString) < 20) Then
  begin
    Result := 0.0;
    Exit;
  end;
  day := ord(DateString[2])-null+(ord(DateString[1])-null)*10;
  month := CalcMonth(DateString);
  year := StrToInt(Copy(DateString,8,4));
{ 12345678901234567890 }
{ 01/Apr/2004:00:00:00 +0200  in TDateTime umwandeln }
  hour := ord(DateString[14])-null+(ord(DateString[13])-null)*10;
  minute := ord(DateString[17])-null+(ord(DateString[16])-null)*10;
  second := ord(DateString[20])-null+(ord(DateString[19])-null)*10;
  if not (TryEncodeDateTime(year, month, day, hour, minute, second, 0, Result)) Then
    Result := 0.0;
End;

{-----------------------------------------------------------------------------
  procedure: ReadDir
  Arguments: ADir, Maske : string; VAR Dateien : DList
  Result:    None

  Reads all files matching a pattern from the current directory and adds all
  file names to the given DList
-----------------------------------------------------------------------------}
procedure ReadDir (ADir, Maske : string; var Dateien : DList);
VAR SR        : TSearchRec;
VAR ThisFName : string;
begin
  if (FindFirst (IncludeTrailingPathDelimiter(ADir)+Maske, faAnyFile, SR) = 0) then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        // Das erste ./ entfernen um relative Namen zu erhalten
        ThisFName := IncludeTrailingPathDelimiter(ADir)+SR.Name;
        ThisFName := Copy (ThisFName,3,Length(ThisFName)-2);

        if (SR.Attr and faDirectory <> faDirectory) then
          Dateien.Add([ThisFName]);
      end;
    until FindNext(SR) <> 0;
  end;
  System.SysUtils.FindClose(SR);
end;

function GetFileList(const FileNameWithPlaceholder: string): DList;
begin
  Result := DList.Create;
  ReadDir('.', FileNameWithPlaceholder, Result);
  if(Result.size = 0) then
    raise Exception.Create(Format('No files found matching %s', [FileNameWithPlaceholder]));
  if(Result.size > 1) then
    Sort(Result);
end;

{ closing streams }

procedure CloseFileStream(const StreamObject: TStreamReader); overload;
begin
  StreamObject.Close;
  StreamObject.Free;
end;

procedure CloseFileStream(const StreamObject: TStreamWriter); overload;
begin
  StreamObject.Flush;
  StreamObject.Close;
  StreamObject.Free;
end;

{ TUTF8N
  ---
  UTF8 encoder without BOM (Byte Order Mark)
}

function TUTF8N.GetPreamble: TBytes;
begin
  Result := nil;
end;


{ TUnixStreamWriter
  ---
  changed NewLine to #10
  initializes with TUTF8N encoder to suppress BOM
}

constructor TUnixStreamWriter.Create(Stream: TStream);
begin
  inherited Create(Stream);
  NewLine := #10;
end;

constructor TUnixStreamWriter.Create(Stream: TStream; Encoding: TEncoding;
  BufferSize: Integer);
begin
  FNoBOMEncoder := TUTF8N.Create;
  inherited Create(Stream, FNoBOMEncoder, BufferSize);
  NewLine := #10;
end;

constructor TUnixStreamWriter.Create(const Filename: string; Append: Boolean);
begin
  inherited Create(FileName, Append);
  NewLine := #10;
end;

constructor TUnixStreamWriter.Create(const Filename: string; Append: Boolean;
  Encoding: TEncoding; BufferSize: Integer);
begin
  inherited Create(FileName, Append, Encoding, BufferSize);
  NewLine := #10;
end;

destructor TUnixStreamWriter.Destroy;
begin
  FNoBOMEncoder.Free;
end;

initialization
{$IFDEF CONSOLE}
  SetConsoleOutputCP(65001);   // utf8 cp
{$ENDIF}
end.
