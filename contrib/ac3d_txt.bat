@echo off
if "%2"=="" goto 01
goto 02

:01
acftools.exe -me -noorder -ac3d "parts\%1.ac" -txt "parts\%1.txt"
goto fim

:02
acftools.exe -me -noorder -ac3d "parts\%1.ac" -txt "parts\%2.txt"
goto fim

:fim