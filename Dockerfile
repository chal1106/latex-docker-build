# Utiliser une image Windows Server Core
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Définir le shell par défaut
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Créer le répertoire de travail
WORKDIR C:\\workspace

# Télécharger et installer MiKTeX
RUN Invoke-WebRequest -Uri 'https://miktex.org/download/ctan/systems/win32/miktex/setup/windows-x64/basic-miktex-24.1-x64.exe' -OutFile 'miktex-installer.exe' ; \
    Start-Process -FilePath 'miktex-installer.exe' -ArgumentList '--unattended', '--auto-install=yes', '--shared=yes' -Wait ; \
    Remove-Item 'miktex-installer.exe' -Force

# Ajouter MiKTeX au PATH
RUN $env:PATH += ';C:\\Program Files\\MiKTeX\\miktex\\bin\\x64' ; \
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

# Créer le répertoire pour les images statiques
RUN New-Item -ItemType Directory -Path 'C:\\workspace\\images' -Force

# Copier les images statiques dans l'image Docker
COPY images/70.jpg C:/workspace/images/
COPY images/arabel.png C:/workspace/images/
COPY images/logo.png C:/workspace/images/
COPY images/ptwin.png C:/workspace/images/
COPY images/cach.png C:/workspace/images/
COPY images/bac.jpg C:/workspace/images/

# Installer les packages LaTeX essentiels
RUN & 'C:\\Program Files\\MiKTeX\\miktex\\bin\\x64\\mpm.exe' --admin --install-some=amsmath,amsfonts,amssymb,graphicx,geometry,fancyhdr,babel,inputenc,fontenc,lmodern,microtype,xcolor,tikz,pgf,booktabs,longtable,array,multirow,hhline,calc,etoolbox,kvsetkeys,ltxcmds,infwarerr,gettitlestring,pdftexcmds,hycolor,hyperref,url,bitset,intcalc,bigintcalc,atbegshi,atveryend,rerunfilecheck,uniquecounter,letltxmacro,hopatch,xcolor-patch,auxhook,kvoptions

# Rafraîchir la base de données des fichiers de noms
RUN & 'C:\\Program Files\\MiKTeX\\miktex\\bin\\x64\\initexmf.exe' --admin --update-fndb

# Définir le point d'entrée par défaut
ENTRYPOINT ["powershell", "-Command"]
CMD ["pdflatex", "--version"]
