# 1. Configuração de caminhos e URLs estruturadas (links diretos / RAW)
$officeDir = "C:\office"
$ohookDir = "C:\ohook"
$urlXml = "https://githubusercontent.com"
$urlSetup = "https://githubusercontent.com"
$urlOhook = "https://githubusercontent.com"

# Garantir TLS 1.2 ativo para os downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Criar diretório do Office e fazer downloads
New-Item -ItemType Directory -Force -Path $officeDir
Invoke-WebRequest -Uri $urlXml -OutFile "$officeDir\configuration-Office365-x64.xml"
Invoke-WebRequest -Uri $urlSetup -OutFile "$officeDir\setup.exe"

# 3. Instalar o Office 365 de forma silenciosa
Start-Process -FilePath "$officeDir\setup.exe" -ArgumentList "/configure configuration-Office365-x64.xml" -WorkingDirectory $officeDir -Wait

# 4. Baixar e extrair o Ohook
New-Item -ItemType Directory -Force -Path $ohookDir
Invoke-WebRequest -Uri $urlOhook -OutFile "$ohookDir\ohook.zip"
Expand-Archive -Path "$ohookDir\ohook.zip" -DestinationPath $ohookDir -Force

# 5. Criar link simbólico e copiar a DLL correspondente ao Ohook
# Executa cmd.exe internamente para processar variáveis de ambiente corretamente
Start-Process cmd.exe -ArgumentList '/c mklink "%ProgramFiles%\Microsoft Office\root\vfs\System\sppcs.dll" "%windir%\System32\sppc.dll"' -Wait
Copy-Item -Path "$ohookDir\sppc64.dll" -Destination "${env:ProgramFiles}\Microsoft Office\root\vfs\System\sppc.dll" -Force

# 6. Adicionar chave no Registro do Windows (HKCU)
$regPath = "HKCU:\Software\Microsoft\Office\16.0\Common\Licensing\Resiliency"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force }
New-ItemProperty -Path $regPath -Name "TimeOfLastHeartbeatFailure" -Value "2040-01-01T00:00:00Z" -PropertyType String -Force

# 7. Testar as chaves sequencialmente via Software Licensing Management (slmgr)
$keys = @(
    "3HYJN-9KG99-F8VG9-V3DT8-JFMHV",
    "Y9NF9-M2QWD-FF6RJ-QJW36-RRF2T",
    "W62NQ-267QR-RTF74-PF2MH-JQMTH",
    "3NMDC-G7C3W-68RGP-CB4MH-4CXCH",
    "H8DN8-Y2YP3-CR9JT-DHDR9-C7GP3",
    "2QCNB-RMDKJ-GC8PB-7QGQV-7QTQJ"
)

foreach ($key in $keys) {
    # Executa o slmgr para injetar a chave e captura o resultado
    $process = Start-Process cscript.exe -ArgumentList "C:\Windows\System32\slmgr.vbs /ipk $key" -NoNewWindow -PassThru -Wait
    
    # Se o slmgr retornar com sucesso (ExitCode 0), interrompe o loop e encerra o script
    if ($process.ExitCode -eq 0) {
        break
    }
}
