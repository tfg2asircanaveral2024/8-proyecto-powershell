# obtener las reglas
$PropiedadesScriptAnalyzer=@()
get-content ./Reglas-ScriptAnalyzer/* | 
    where { -not ($_ -match '^#') } | 
    ForEach-Object { $PropiedadesScriptAnalyzer += $_ }

# Realizar los tests. Invoke-ScriptAnalyzer no genera errores determinantes, así que no se cancela la ejecución del script aunque se rompan algunas reglas 
$TestsScriptAnalyzer=Invoke-ScriptAnalyzer -Path ./Gestionar-Datos.ps1 -IncludeRule $PropiedadesScriptAnalyzer

# si se ha quebrantado alguna regla, se envía un error determinante
if (($TestsScriptAnalyzer | measure).count -gt 0) {
    Throw "Ha habido $(($TestsScriptAnalyzer | measure).count) errores de PSScriptAnalyzer.$($TestsScriptAnalyzer | select Line,RuleName,Message,Severity)"
} else {
    Write-Output "Se han superado los tests de PSScriptAnalyzer."
}