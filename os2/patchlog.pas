Program PatchLog;

{ Patchar logrutinsanropen }

Uses DOS;

Var
  infile, outfile: text;
  prgline: string;
  i: integer;
  quit: boolean;
  Tid1, Tid2: longint;
Begin
  If ParamCount < 2 then begin
    Writeln(ParamStr(0), ' infil utfil');
    Halt(1);
  end;
  Write(ParamStr(1), ' => ', ParamStr(2));
  Assign(infile, ParamStr(1));
  Assign(outfile, ParamStr(2));
  Reset(infile);
  {$I-}
  Reset(outfile);
  If IOResult = 0 then begin
    GetFTime(infile, Tid1);
    GetFTime(outfile, Tid2);
    If Tid1 <= Tid2 then begin
      Close(infile);
      Close(outfile);
      Writeln(' [is up-to-date]');
      Halt(1);
    end;
    Close(outfile);
  end;
  {$I+}
  Rewrite(outfile);
  While not eof(infile) do begin
    Readln(infile, prgline);
    If Pos('Log^.', prgline) > 0 then begin
      quit := false;
      Repeat
        i := Pos('Log^.', prgline);
        If (copy(prgline, i + 5, 2) = 'is') or
           (copy(prgline, i + 5, 7) = 'OpenLog') then begin
          Write(outfile, Copy(prgline, 1, i + 4));
          prgline := copy(prgline, i + 5, Length(prgline) - i - 4);
          i := -1;
        end;
      Until i >= 0;
      If i = 0 then
        Writeln(outfile, prgline)
      else begin
        Write(outfile, Copy(prgline, 1, i + 4));
        prgline := copy(prgline, i + 5, Length(prgline) - i - 4);

        i := 1;
        Repeat
          Repeat
            If i > length(prgline) then begin
              Readln(infile, prgline);
              i := 1;
              If Pos('else', prgline) > 0 then quit := true;
              While not quit and (prgline[i] = ' ') do begin
                Inc(i);
                If i > length(prgline) then begin
                  Readln(infile, prgline);
                  i := 1;
                end;
              end;
            end;
            Write(outfile, prgline[i]);
            Inc(i);
          Until (prgline[i] = ';') or (prgline[i] = '^') or quit;
          If (prgline[i] <> ';') and not quit then
            Write(outfile, '; Log');
        Until (prgline[i] = ';') or quit;
        If quit then
          Writeln(outfile, copy(prgline, i, length(prgline) - i + 1))
        else
          Writeln(outfile, ';');
        quit := false;
      end;
    end else
      Writeln(outfile, prgline);
  end;
  Writeln(' [ok]');
  Close(infile);
  Close(outfile);
End.
