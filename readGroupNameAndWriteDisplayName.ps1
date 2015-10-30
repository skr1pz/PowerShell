PS C:\Users\MDMAYER01> PS C:\Users\syuserver> get-adgroup -filter 'groupcategory -eq "distribution"' | %{set-adgroup -Id
entity $_.Name -DisplayName $_.Name}