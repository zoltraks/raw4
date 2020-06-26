unit main;

{$MODE objfpc}{$H+}
{$WARN 5057 off : Local variable "$1" does not seem to be initialized}

interface

procedure Run();

implementation

uses
  Classes, SysUtils;

type
  TOptions = object
    Help: Boolean;
    Input: String;
    Output: String;
    Force: Boolean;
    Verbose: Boolean;
    Average: Boolean;
    Reverse: Boolean;
  end;

  TState = object
    Options: TOptions;
    Source: String;
    Destination: String;
  end;

var
  State: TState;

procedure Run();

var
  I, C: Integer;
  S: String;
  B, X: Byte;

  TotalBytesRead, BytesRead, TotalBytesWritten: Int64;
  InputBuffer: array [0..4096 - 1] of Byte;
  OutputBuffer: array [0..2048 - 1] of Byte;
  InputFileStream: TFileStream;
  OutputFileStream: TFileStream;

begin

  { parse command line arguments }

  I := 0;
  while (I < ParamCount) do
  begin
    Inc(I);
    S := ParamStr(I);
    if (S.StartsWith('-') or S.StartsWith('/')) then
    begin
      case S of
        '-h', '--help', '/?', '/help':
          State.Options.Help := True;
        '-v', '--verbose', '/v', '/verbose':
          State.Options.Verbose := True;
        '-f', '--force', '/f', '/force':
          State.Options.Force := True;
        '-a', '--average', '/a', '/average':
          State.Options.Average := True;
        '-r', '--reverse', '/r', '/reverse':
          State.Options.Reverse := True;
        '-i', '--input', '/i', '/input':
        begin
          Inc(I);
          S := ParamStr(I);
          State.Options.Input := S;
        end;
        '-o', '--output', '/o', '/output':
        begin
          Inc(I);
          S := ParamStr(I);
          State.Options.Output := S;
        end
        else
        begin
          WriteLn(Format('Unrecognized option: %s', [S]));
          Exit;
        end;
      end;
      continue;
    end;
    if (S = '/?') then
    begin
      State.Options.Help := True;
      continue;
    end;
    if (0 = Length(State.Options.Input)) then
    begin
      State.Options.Input := S;
      continue;
    end;
    if (0 = Length(State.Options.Output)) then
    begin
      State.Options.Output := S;
      continue;
    end;
    WriteLn(Format('Unexpected argument: %s', [S]));
    Exit;
  end;

  { help }

  if State.Options.Help then
  begin
    WriteLn('8-bit to 4-bit data conversion tool');
    WriteLn('Author: Filip Golewski');
    WriteLn('Link: http://github.com/zoltraks/raw4.git');
    WriteLn();
    WriteLn('Options:');
    WriteLn();
    WriteLn('  -i <source>');
    WriteLn('  --input <source>');
    WriteLn();
    WriteLn('     Source file for reading');
    WriteLn();
    WriteLn('  -o <destination>');
    WriteLn('  --output <destination>');
    WriteLn();
    WriteLn('     Destination file for writing');
    WriteLn();
    WriteLn('  -v');
    WriteLn('  --verbose');
    WriteLn();
    WriteLn('     Verbose mode');
    WriteLn();
    WriteLn('  -f');
    WriteLn('  --force');
    WriteLn();
    WriteLn('     Force destination file overwrite if exists');
    WriteLn();
    WriteLn('  -r');
    WriteLn('  --reverse');
    WriteLn();
    WriteLn('     Reverse output data nibble order');
    WriteLn();
    WriteLn('  -a');
    WriteLn('  --average');
    WriteLn();
    WriteLn('     Round input value instead of ceiling');
    Exit;
  end;

  { check file options }

  State.Source := State.Options.Input;
  State.Destination := State.Options.Output;

  if 0 = Length(State.Source) then
  begin
    Write('Source file: ');
    ReadLn(State.Source);
    if 0 = Length(State.Source) then
    begin
      WriteLn('Source file is not defined');
      Exit;
    end;
    if 0 = Length(State.Destination) then
    begin
      S := ChangeFileExt(State.Source, '.out');
      Write(Format('Destination file [%s]: ', [S]));
      ReadLn(State.Destination);
      if 0 = Length(State.Destination) then
      begin
        State.Destination := S;
      end;
    end;
  end;

  if 0 = Length(State.Destination) then
  begin
    S := ChangeFileExt(State.Source, '.out');
    State.Destination := S;
  end;

  if (State.Options.Verbose) then
  begin
    WriteLn(Format('Source file: %s', [State.Source]));
    WriteLn(Format('Destination file: %s', [State.Destination]));
  end;

  if not FileExists(State.Source) then
  begin
    WriteLn(Format('Error: Source file %s not exists', [State.Source]));
    Exit;
  end;

  if FileExists(State.Destination) then
  begin
    if not State.Options.Force then
    begin
      WriteLn(Format('Error: Destination file %s exists', [State.Destination]));
      Exit;
    end
    else if State.Options.Verbose then
    begin
      WriteLn('Destination file exists and will be overwritten');
    end;
  end;

  { do the stuff }

  try
    InputFileStream := TFileStream.Create(State.Source, fmOpenRead);
    try
      OutputFileStream := TFileStream.Create(State.Destination, fmCreate or fmOpenWrite);
      try
        TotalBytesRead := 0;
        TotalBytesWritten := 0;
        while TotalBytesRead <= InputFileStream.Size do
        begin
          BytesRead := InputFileStream.Read(InputBuffer, SizeOf(InputBuffer));
          if 0 = BytesRead then
            break;
          Inc(TotalBytesRead, BytesRead);
          I := 0;
          C := 0;
          while I < BytesRead do
          begin
            B := InputBuffer[i];
            X := 0;
            if State.Options.Average and (B < 256 - 16) and (7 < B mod 16) then
              Inc(X);
            B := B shr 4;
            Inc(B, X);
            if 0 = I mod 2 then
            begin
              if State.Options.Reverse then
                OutputBuffer[C] := B
              else
                OutputBuffer[C] := B shl 4;
            end
            else
            begin
              if State.Options.Reverse then
                Inc(OutputBuffer[C], B shl 4)
              else
                Inc(OutputBuffer[C], B);
              Inc(C);
            end;
            Inc(I);
          end;
          Inc(C);
          OutputFileStream.Write(OutputBuffer, C);
          Inc(TotalBytesWritten, C);
        end;
      finally
        OutputFileStream.Free;
      end;
    finally
      InputFileStream.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn(Format('Exception: %s ', [E.Message]));
      Exit;
    end;
  end;

  if State.Options.Verbose then
  begin
    WriteLn(Format('Total bytes read: %d', [TotalBytesRead]));
    WriteLn(Format('Total bytes written: %d', [TotalBytesWritten]));
  end;
end;

end.



