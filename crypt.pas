{************************************************************************}
{* Modul:       crypt.pas                                               *}
{************************************************************************}
{* Inneh†ll:    LocalPost kodgenererare                                 *}
{************************************************************************}
{* Funktion:    Genererar registreringskod f”r LocalPost                *}
{************************************************************************}
{* Rutiner:     RegiCode                                                *}
{************************************************************************}

Unit Crypt;

Interface

Function RegiCode(RegiName:string):longint;

Implementation

const
        InitialValue    = 7194;
        CharacterKey    = 3;
        PositionKey     = 14;
        AdditionKey     = 42;
        MultiplicationKey=3;

{************************************************************************}
{* Rutin:       RegiCode                                                *}
{************************************************************************}
{* Inneh†ll:    Skapar registreringskod f”r TextVert                    *}
{* Definition:  Function RegiCode(RegiName:string):longint;             *}
{************************************************************************}

Function RegiCode(RegiName:string):longint;
var
  Tp,i: integer;
begin
  Tp:=InitialValue;
  For i:=1 to Length(RegiName) do
  begin
    Tp:=Tp+(Ord(RegiName[i])+CharacterKey)*(PositionKey+i);
    While Tp>4000 do Tp:=Tp-4000;
  end;
  RegiCode:=(Tp+AdditionKey)*MultiplicationKey;
end;

end.
