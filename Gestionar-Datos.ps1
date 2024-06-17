###################### COMANDO PRINCIPAL - GESTIONAR-DATOS

function Gestionar-Datos {
    [CmdletBinding()]
    param (
        [ValidateSet('PSObject','CSV','YAML')]
        [string]
        $TipoDatoEntrada='PSObject',
    
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True
        )]
        $DatoEntrada=$null,
    
        [string[]]
        $RutaDatoEntrada="",
    
        [ValidateSet('PSObject','CSV','YAML')]
        [string]
        $TipoDatoSalida='PSObject',
    
        [string[]]
        $RutaDatoSalida=$null,
    
        [switch]
        $PassThru=$False
    )
    
    BEGIN {
        $DatoSalida=@()
    }
    
    PROCESS {
        # si se han usado los dos parámetros que permiten introducir datos, salir con un error
        if (($DatoEntrada) -and ($RutaDatoEntrada -ne "")) {
            Throw "Parece que has intentado introducir datos tanto desde una ruta como desde la Pipeline o a través del parámetro -DatoEntrada. Debes escoger solamente uno de los dos métodos."
        }
    
        # obtener datos de las rutas pasadas al parámetro $RutaFicheroEntrada y volcarlo en el parámetro $DatoEntrada
        if ($RutaDatoEntrada) {
            $DatoEntrada=@()  
            
            if ($TipoDatoEntrada -eq 'CSV') {
                $EncabezadoCSV=""
            } elseif ($TipoDatoEntrada -eq 'YAML') {
                $ObjetosSuperioresYAML=@()
            }
            
            foreach ($Ruta in $RutaDatoEntrada) {
                # comprobar si todas las rutas existen, y si no, se cancela la operación
                if (-not (Test-Path $Ruta)) {
                    Throw "La ruta $Ruta no existe o no está disponible actualmente"
                } else {
                    $RutaFicheros=@()
                    # si la ruta es un directorio, se obtienen todos los ficheros y se introducen sus rutas en $RutaFichero
                    if (Test-Path $Ruta -PathType Container) {
                        $RutaFicheros = Get-ChildItem -Path $Ruta -Recurse | Where-Object {$_.VersionInfo -like '*File*'}
                    } else {
                        # si la ruta es un archivo, $RutaFicheros solo debe apuntar a la ruta indicada
                        $RutaFicheros=Get-ChildItem -Path $Ruta
                    }

                    # procesar la ruta (en caso de que $Ruta fuese un fichero) o rutas (en caso de que $Ruta fuese un directorio)
                    foreach ($RutaFichero in $RutaFicheros) {
                        try {
                            # intentar obtener el contenido del archivo, si se falla, se cancela la operación
                            $Contenido=Get-Content $RutaFichero.FullName -ErrorAction Stop | 
                                Where-Object { -not ($_ -match '^#') }
                            
                            # si el contenido del fichero es CSV, primero analizamos la primera línea, que tiene los encabezados, es decir, los tipos de datos a los que el resto de líneas hacen referencia, y los analizamos para saber si el archivo actual contiene objetos con la misma estructura de los que ya tenemos 
                            if ($TipoDatoEntrada -eq 'CSV') {
                                # si la variable $EncabezadoCSV no existe, es la primera vuelta del bucle, así que se inicializa. Es la cabecera del primer archivo obtenido
                                if ($EncabezadoCSV -eq "") {
                                    $EncabezadoCSV=$Contenido[0]
                                    $Posicion=0
                                }

                                # si el encabezado del archivo actual coincide con $EncabezadoCSV, se permite la operación, en caso contrario, por la naturaleza del lenguaje CSV, no podemos incluir varios tipos de objetos distintos en el mismo archivo, por lo que se salta con un error
                                if ($Contenido[0] -eq $EncabezadoCSV) {
                                    # apendizamos el contenido del archivo actual, sin incluir la cabecera, a la información previa
                                    $DatoEntrada = $DatoEntrada + $Contenido[$Posicion..$Contenido.Count]

                                    # comprobamos si $Posicion es 0, porque al volcar el contenido del primer archivo queremos incluir también la cabecera, que es la posicion 0 de contenido, pero de los siguientes ficheros solo queremos las posiciones a partir de la primera, porque si incluyéramos también la cabecera sería interpretada erróneamente como datos
                                    if ($Posicion -eq 0) {
                                        $Posicion=1
                                    }
                                } else {
                                    Throw "El archivo $($RutaFichero.FullName) tiene un encabezado distinto al usado como referencia. Se están intentando usar tipos de objetos diferentes."
                                }                            
                            } elseif ($TipoDatoEntrada -eq 'YAML') {
                                # si estamos trabajando con YAML, debemos asegurarnos de que el contenido de los archivos no define a los mismos objetos de orden superior, o de lo contrario, provoca el error de Clave Duplicada
                                # para ubicar a los objetos de orden superior, suponemos que son aquellos cuya línea no está indentada
                                $ObjetosSuperioresYAMLLocal=((
                                    $Contenido | 
                                    Where-Object {
                                        (-not ($_ -match '^ ')) -and `
                                        (-not ($_ -match '^-'))
                                    }) -Split ':')[0]


                                # iterar por los objetos obtenidos
                                foreach ($ObjetoSuperiorYAMLLocal in $ObjetosSuperioresYAMLLocal) {
                                    # si el objeto actual ya se encuentra entre los objetos analizados, se sale con un error
                                    if ($ObjetoSuperiorYAMLLocal -in $ObjetosSuperioresYAML) {
                                        Throw "El objeto de orden superior $ObjetoSuperiorYAMLLocal se encuentra en varias ubicaciones, o bien de un mismo fichero o de varios, y esa acción no está permitida"
                                    } else {
                                        # se añade el nuevo objeto superior al listado para tenerlo en cuenta en la siguiente vuelta del bucle
                                        $ObjetosSuperioresYAML += $ObjetoSuperiorYAMLLocal
                                    }
                                }
                                $DatoEntrada += $Contenido
                            } else {
                                # si no estamos tratando con CSV o YAML, no necesitamos complejidad adicional
                                $DatoEntrada += $Contenido
                            }
                        } catch {
                            Throw $Error[0].Exception
                        }
                    }
                }
            }
        }
    
        # convertir la informacion a PSObject, tratándola diferente según el formato solicitado.
        if ($TipoDatoEntrada -eq 'PSObject') {
            $DatoSalida += $DatoEntrada
        } elseif ($TipoDatoEntrada -eq 'CSV') {
            try {
                $DatoSalida += $DatoEntrada | ConvertFrom-Csv -ErrorAction Stop
            } catch {
                Throw $Error[0].Exception
            }
        } elseif ($TipoDatoEntrada -eq 'YAML') {
            try {
                $DatoSalida += new-object -TypeName psobject -Property ($DatoEntrada | ConvertFrom-Yaml -ErrorAction Stop)
            } catch {
                Throw $Error[0].Exception
            }
        }
    } # PROCESS
    
    END {
        # ahora que la información ha sido convertida a PSObject, es convertida al formato de destino. No se incluye código para PSObject porque los datos ya están en ese formato
        if ($TipoDatoSalida -eq 'CSV') {
            try {
                #$DatoSalida=$DatoSalida | ForEach-Object { ConvertTo-Csv -ErrorAction Stop }
                $DatoSalida=$DatoSalida | ConvertTo-Csv -ErrorAction Stop
            } catch {
                Throw $Error[0].Exception
            }
        } elseif ($TipoDatoSalida -eq 'YAML') {
            try {
                $DatoSalida=$DatoSalida | ConvertTo-Yaml -ErrorAction Stop
            } catch {
                Throw $Error[0].Exception
            }
        }
    
        # enviar la información al destino o destinos indicados
        # enviar los datos a los ficheros de destino indicados. Puede ser más de uno
        if ($RutaDatoSalida) {
            foreach ($RutaSalida in $RutaDatoSalida) {
                # comprobar si la ruta es hacia un directorio, y en ese caso, saltar con un error
                if (Test-Path $RutaSalida -PathType Container) {
                    Throw "La ruta $RutaSalida apunta a un directorio, no se puede enviar la información"
                } else {
                    # si la ruta es un fichero o no existe, se intenta crear el archivo o escribir la información, perdiendo lo que hbubiera
                    try {
                        $DatoSalida | Out-File $RutaSalida
                    } catch {
                        Throw $Error[0].Exception
                    }
                }
            }
    
            # si $PassThru vale $True, ademas de enviar la información a uno o varios ficheros, se envía a la Pipeline
            if ($PassThru) {
                $DatoSalida
            }
        } else {
            # enviar los datos a la pipeline
            $DatoSalida
        }
    } # END
} # FUNCTION Gestionar-Datos