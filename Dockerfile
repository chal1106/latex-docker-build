# Utiliser une image Windows Server Core
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Définir le shell par défaut avec gestion d'erreurs améliorée
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Metadata pour l'image
LABEL maintainer="chal1106@usherbrooke.ca" \
      description="LaTeX environment with MiKTeX on Windows Server Core" \
      version="1.0"

# Créer le répertoire de travail
WORKDIR C:\\workspace

# Configuration réseau et sécurité pour téléchargement
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Télécharger et installer MiKTeX avec gestion d'erreur robuste
RUN Write-Host 'Téléchargement de MiKTeX...' ; \
    $maxAttempts = 3; \
    $attempt = 0; \
    $urls = @( \
        'https://ctan.org/tex-archive/systems/win32/miktex/setup/windows-x64/basic-miktex-24.1-x64.exe', \
        'https://miktex.org/download/ctan/systems/win32/miktex/setup/windows-x64/basic-miktex-24.1-x64.exe' \
    ); \
    do { \
        $attempt++; \
        foreach ($url in $urls) { \
            try { \
                Write-Host "Tentative $attempt - URL: $url"; \
                Invoke-WebRequest -Uri $url -OutFile 'miktex-installer.exe' -UseBasicParsing; \
                Write-Host 'Téléchargement réussi!'; \
                break; \
            } catch { \
                Write-Host "Échec: $_"; \
                if ($url -eq $urls[-1] -and $attempt -eq $maxAttempts) { \
                    throw "Tous les téléchargements ont échoué"; \
                } \
            } \
        } \
        if (Test-Path 'miktex-installer.exe') { break } \
        Start-Sleep -Seconds 10; \
    } while ($attempt -lt $maxAttempts); \
    \
    Write-Host 'Installation de MiKTeX...' ; \
    Start-Process -FilePath 'miktex-installer.exe' -ArgumentList '--unattended', '--auto-install=yes', '--shared=yes', '--package-set=basic' -Wait ; \
    Remove-Item 'miktex-installer.exe' -Force

# Ajouter MiKTeX au PATH
RUN $env:PATH += ';C:\\Program Files\\MiKTeX\\miktex\\bin\\x64' ; \
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

# Créer le répertoire pour les images statiques
RUN New-Item -ItemType Directory -Path 'C:\\workspace\\images' -Force

# Copier les images statiques dans l'image Docker (si elles existent)
# COPY images/ C:/workspace/images/

# Installer les packages LaTeX essentiels
RUN Write-Host 'Installation des packages LaTeX...' ; \
    & 'C:\\Program Files\\MiKTeX\\miktex\\bin\\x64\\mpm.exe' --admin --install-some=amsmath,amsfonts,amssymb,graphicx,geometry,fancyhdr,babel,inputenc,fontenc,lmodern,microtype,xcolor,tikz,pgf,booktabs,longtable,array,multirow,hhline,calc,etoolbox,kvsetkeys,ltxcmds,infwarerr,gettitlestring,pdftexcmds,hycolor,hyperref,url,bitset,intcalc,bigintcalc,atbegshi,atveryend,rerunfilecheck,uniquecounter,letltxmacro,hopatch,xcolor-patch,auxhook,kvoptions

# Rafraîchir la base de données des fichiers de noms
RUN & 'C:\\Program Files\\MiKTeX\\miktex\\bin\\x64\\initexmf.exe' --admin --update-fndb

# Test de l'installation
RUN Write-Host 'Test de l\installation...' ; \
    & 'C:\\Program Files\\MiKTeX\\miktex\\bin\\x64\\pdflatex.exe' --version

# Définir le point d'entrée par défaut
ENTRYPOINT ["powershell", "-Command"]
CMD ["pdflatex", "--version"]
