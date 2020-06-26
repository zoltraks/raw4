unit utf8console;

{$MODE objfpc}{$H+}

interface

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils;

implementation

var
  RestoreConsoleCP: Boolean = False;
  RestoreCodePage: Boolean = False;

  PreviousConsoleCP: UINT;
  PreviousCodePage: UINT;

initialization

  {$IFDEF WINDOWS}
  PreviousConsoleCP := GetConsoleOutputCP;
  if (PreviousConsoleCP <> CP_UTF8) then
  begin
    RestoreConsoleCP := True;
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
  end;
  {$ENDIF}

  PreviousCodePage := GetTextCodePage(Output);
  if (PreviousCodePage <> CP_UTF8) then
  begin
    RestoreCodePage := True;
    SetTextCodePage(Output, CP_UTF8);
    SetTextCodePage(Input, CP_UTF8);
  end;

finalization

  {$IFDEF WINDOWS}
  if (RestoreConsoleCP) then
  begin
    SetConsoleOutputCP(PreviousConsoleCP);
    SetConsoleCP(PreviousConsoleCP);
  end;
  {$ENDIF}

  if (RestoreCodePage) then
  begin
    SetTextCodePage(Output, PreviousCodePage);
    SetTextCodePage(Input, PreviousCodePage);
  end;

end.

