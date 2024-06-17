pipeline {
    agent any

    stages {
        stage('Importar Repositorio') {
            steps {
                // ERROR: eliminar la linea descomentada, y descomentar la línea comentada para resolver el error
                git branch: 'unaramaquenoexiste', url: 'https://github.com/tfg2asircanaveral2024/8-proyecto-powershell.git'
                // git branch: 'correcto', url: 'https://github.com/tfg2asircanaveral2024/8-proyecto-powershell.git'
            }
        }
        stage('Dependencias (PSDepend)') {
            steps {
                pwsh 'Invoke-PSDepend -Path ./Dependencias -Force -ErrorAction Stop'
            }
        }
        stage('Tests (Pester)') {
            steps {
                pwsh 'Invoke-Pester'
            }
        }
        stage('Tests (PSScriptAnalyzer)') {
            steps {
                pwsh './Gestionar-Datos.ScriptAnalyzer.ps1'
            }
        }
        stage('Despliegue a la rama Produccion de GitHub') {
            steps {
                sh 'chmod u+x script-despliegue-git.sh'                
                sh './script-despliegue-git.sh'
            }
        }
    }
}
