@{
    # opciones para el comportamiento de PSDepend
    PSDependOptions = @{
        Parameters = @{
            Import = $True
            SkipPublisherCheck = $True
            Repository = 'PSGallery'
        }
    }

    # modulos requeridos por la herramienta propiamente dicha
    'powershell-yaml' = @{
        Name = 'powershell-yaml'
        Version = 'latest'
    }
}