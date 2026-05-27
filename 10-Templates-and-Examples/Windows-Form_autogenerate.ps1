# Leer el archivo XML en una variable
[xml]$domainsXml = Get-Content -Path '.\domains.xml'

# Inicializar un array vacío para almacenar los objetos de dominio
$domainObjects = @()

# Iterar sobre cada elemento de "Configuration" en el XML
foreach ($config in $domainsXml.Configurations.Configuration) {
    # Crear un objeto personalizado para cada "Configuration"
    $domainObject = [PSCustomObject]@{
        Domain   = $config.Domain
        FilePath = $config.FilePath
    }
    
    # Añadir el objeto personalizado al array
    $domainObjects += $domainObject
}

# Ahora, $domainObjects es un array de objetos con propiedades "Domain" y "FilePath"
# Import the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Initialize main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = 'Port Query Report'
$mainForm.Width = 800
$mainForm.Height = 400

# Create ComboBox for domain selection
$domainComboBox = New-Object System.Windows.Forms.ComboBox
$domainComboBox.Location = New-Object System.Drawing.Point(20, 20)
$domainComboBox.Size = New-Object System.Drawing.Size(200, 30)
$domainComboBox.Items.Add("Select Domain")
foreach ($domain in $domainObjects) {
    $domainComboBox.Items.Add($domain.Domain)
}
$domainComboBox.SelectedIndex = 0

$labeldomain = New-Object System.Windows.Forms.Label
$labeldomain.Text = 'Domain: Not selected'
$labeldomain.Width = 300
$labeldomain.Location = New-Object System.Drawing.Point(250, 25)

$mainForm.Controls.Add($labeldomain)
$mainForm.Controls.Add($domainComboBox)

# Show the form
$mainForm.ShowDialog()