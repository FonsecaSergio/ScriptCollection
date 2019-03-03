$fso = Get-ChildItem -Recurse -path "D:\Fotos"
$fsoBU = Get-ChildItem -Recurse -path "D:\OneDrive\Pictures\Imagens"
$X = Compare-Object -ReferenceObject $fso -DifferenceObject $fsoBU  -Property Name,Length
$X | Out-GridView