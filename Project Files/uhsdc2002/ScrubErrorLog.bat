Forfiles.exe -p C:\Scripts\ErrorLogBackup -m *.txt -d -5 -c "Cmd.exe /C del @path"