@{
    # opciones para el comportamiento de PSDepend
    PSDependOptions = @{
        Parameters = @{
            Import = $True
            SkipPublisherCheck = $True
            Repository = 'PSGallery'
        }
    }

    # modulos requeridos por el proceso CI/CD
    Pester = @{
        Name = 'pester'
        Version = 'latest'
    }

    PSScriptAnalyzer = @{
        Name = 'PSScriptAnalyzer'
        Version = 'latest'
    }    
}