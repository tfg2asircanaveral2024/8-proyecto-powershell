BeforeAll {
    # ejecutar el script usando dot-sourcing, para cargar en memoria las funciones que contiene 
    . ./Gestionar-Datos.ps1

    # definimos un objeto para poder realizar pruebas con informacion
    $HashtableObjeto=@(
        @{ 'Nombre'='Pepa'; 'Ombligo'='Peludo' }, 
        @{ 'Nombre'='Pepe'; 'Ombligo'='Rasurado' }
    )

    $Objeto=$HashtableObjeto | foreach { New-object -TypeName psobject -Property $_ }
}

Describe 'Tests básicos' {
    It 'Debería recibir objetos desde un parámetro y pasarlos sin modificar' {
        # como no se usa ningun parametro, -TipoDatoEntrada y -TipoDatoSalida valen PSObject, y sin ingún otro parámetro, los valores son recibidos desde la Pipeline y enviados a ella de nuevo, por lo que en este caso el objeto pasado al comando debería salir inalterado
        (
            Compare-Object $Objeto (
                $Objeto | ForEach-Object { Gestionar-Datos -DatoEntrada $_ }
            ) | 
            Measure-Object
        ).count |
        Should -Be 0   
    }

    It 'Debería recibir objetos desde la Pipeline y pasarlos inalterados' {
        # este ejemplo es similar al anterior, pero en lugar de recibir los objetos por la Pipeline, se utiliza el parámetro DatoEntrada
        (
            Compare-Object $Objeto (
                $Objeto | Gestionar-Datos 
            ) | 
            Measure-Object
        ).count |
        Should -Be 0   
    }

    It 'Debería dar un error cuando se usan tanto el parámetro $DatoEntrada como $RutaDatoEntrada' {
        { $Objeto | Gestionar-Datos -RutaDatoEntrada . } | 
            Should -Throw

        { Gestionar-Datos -DatoEntrada $Objeto -RutaDatoEntrada . } | 
            Should -Throw
    }

    It 'Debería dar un error al indicar un tipo de dato no soportado' {
        { Gestionar-Datos -TipoDatoEntrada Syslog } | 
            Should -Throw
        
        { Gestionar-Datos -TipoDatoSalida Syslog } | 
            Should -Throw
    }
}

Describe 'Tests para CSV' {
    BeforeAll {
        $ObjetoCsv=$Objeto | ConvertTo-Csv
        $RutaFicherosCsv='./ficheros-csv'
    }

    It 'Debería convertir un objeto a CSV' {
        (
            Compare-Object $ObjetoCsv (
                $Objeto | Gestionar-Datos -TipoDatoSalida CSV
            ) | 
            Measure-Object
        ).count |
        Should -Be 0
    }

    It 'Debería convertir el objeto a CSV y crear un fichero' {
        $Objeto | Gestionar-Datos -TipoDatoSalida CSV -RutaDatoSalida ./Fichero-Pester.csv
        
        (
            Compare-Object $ObjetoCsv (
                Get-Content -Path ./Fichero-Pester.csv
            ) | 
            Measure-Object
        ).count |
        Should -Be 0
    }

    It 'Debería recibir correctamente la información desde unos ficheros' {
        (
            Compare-Object $Objeto (
                Gestionar-Datos -TipoDatoEntrada CSV -RutaDatoEntrada ./ficheros-csv/fichero1.csv,./ficheros-csv/fichero2.csv
            ) | 
            Measure-Object
        ).count |
        Should -Be 0
    }

    # en la ruta ./ficheros-csv hay tres ficheros, y el archivo con un '3' en en nombre no tiene la misma cabecera, es decir, las mismas propiedades de objeto, que los demás, por lo que al importarlo debería fallar
    It 'Debería fallar cuando la información no es consistente entre ficheros' {
        { Gestionar-Datos -TipoDatoEntrada CSV -RutaDatoEntrada ./ficheros-csv } | 
            Should -Throw            
    }

    AfterAll {
        Remove-Item ./Fichero-Pester.csv
    }
}

Describe 'Tests para YAML' {
    BeforeAll {
        $ObjetoYaml=$Objeto[0] | ConvertTo-Yaml
        $RutaFicherosYaml='./ficheros-yaml'
    }

    It 'Debería convertir un objeto a YAML' {
        (
            Compare-Object $ObjetoYaml (
                $Objeto[0] | Gestionar-Datos -TipoDatoSalida YAML
            ) | 
            Measure-Object
        ).count |
        Should -Be 0
    }

    It 'Debería convertir un objeto a YAML y enviarlo a un fichero' {
        $Objeto[0] | Gestionar-Datos -TipoDatoSalida YAML -RutaDatoSalida ./Fichero-Pester.yaml

        (
            Compare-Object ($ObjetoYaml -split "`n") (
                Get-Content ./Fichero-Pester.yaml
            ) | 
            Measure-Object
        ).count |
        Should -Be 0
    }

    It 'Debería poder importar YAML desde unos ficheros' {
        (
            Compare-Object $ObjetoYaml (
                Gestionar-Datos -TipoDatoEntrada YAML -RutaDatoEntrada ./ficheros-yaml/fichero1.yaml,./ficheros-yaml/fichero2.yaml -TipoDatoSalida YAML
            ) | 
            Measure-Object
        ).count |
        Should -Be 0
    }

    # en la ruta ./ficheros-yaml hay tres ficheros, y el archivo fichero3.yaml utiliza el objeto Nombre, que ya había sido definido previamente por fichero1.yaml, por lo que al importarlo debería fallar
    It 'Debería fallar cuando se usa el mismo objeto superior varias veces' {
        { Gestionar-Datos -TipoDatoEntrada YAML -RutaDatoEntrada ./ficheros-yaml } | 
            Should -Throw            
    }

    AfterAll {
        Remove-Item ./Fichero-Pester.yaml
    }
}
