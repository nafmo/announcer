@Echo off
if %1!==! goto fel
Echo Announcer v%1 >! Input.Txt
Echo þ Siduppdelar
c:\dev\bas\src\pager\Pager Document.Txt Announce.Doc Input.Txt /OY /L0 /ML9 /MR75 /HL9 /HR75 /A196 /PA /T46 /BL9 /BR75 /CF
c:\dev\bas\src\pager\Pager Dokument.Txt Announce.Dok Input.Txt /OY /L1 /ML9 /MR75 /HL9 /HR75 /A196 /PA /T46 /BL9 /BR75 /CF
Del Input.Txt
Echo þ Visar filerna
List Announce.Do? Do?ument.Txt
goto slut
:fel
echo PAGE versionsnr.           Exempel: PAGE 2.20
:slut
