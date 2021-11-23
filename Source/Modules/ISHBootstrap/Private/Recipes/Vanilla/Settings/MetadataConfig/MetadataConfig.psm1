set-strictmode -version 2.0

# Get default metadata configuration path
function Get-DefaultMetadataConfigurationPath {
    param([string]$basePath)
    if (-not $basePath) {
        $path = "$PSScriptRoot\..\..\..\Configuration\ClientConfig\MetadataConfig.xml"
    }
    else {
        $path = $basePath + "\Author\ASP\ClientConfig\MetadataConfig.xml"
    }
    return $path
}

# Load metadata configuration
function Get-MetadataConfiguration {
    param([string]$filePath)
    Write-Verbose "Load metadata configuration from '$filePath'."
    $document = New-Object System.Xml.XmlDocument
    $document.PreserveWhitespace = $true
    $document.Load($filePath)
    return $document
}

# Save metadata configuration
function Save-MetadataConfiguration {
    param([Xml.XmlDocument]$document, [string]$filePath)
    Write-Verbose "Save metadata configuration to '$filePath'."
    $document.Save($filePath)
}

function AppendChild {
    param([Xml.XmlDocument]$document, [string]$xpathExists, [string]$xpath, [string]$content)
    [Xml.XmlElement]$elementExists = $document.SelectSingleNode($xpathExists)
    if ($elementExists -eq $null) {
        [Xml.XmlElement]$element = $document.SelectSingleNode($xpath)
        if ($element -ne $null) {
            Write-Verbose "Append child node."
            $newelement = [xml]"<dummy xml:space='preserve'>$content</dummy>"
            $childNodes = $newelement.DocumentElement.ChildNodes
            foreach ($childNode in $childNodes) { 
                $importNode = $element.OwnerDocument.ImportNode($childNode, $true)
                $element.AppendChild($importNode)
            }
        }
        else {
            throw "XPath could not be found ($xpath)."
        }
    }
}

function InsertAfter {
    param([Xml.XmlDocument]$document, [string]$xpathExists, [string]$xpath, [string]$content)
    [Xml.XmlElement]$elementExists = $document.SelectSingleNode($xpathExists)
    if ($elementExists -eq $null) {
        [Xml.XmlElement]$element = $document.SelectSingleNode($xpath)
        if ($element -ne $null) {
            Write-Verbose "Insert child nodes."
            $newelement = [xml]"<dummy xml:space='preserve'>$content</dummy>"
            $childNodes = $newelement.DocumentElement.ChildNodes
            $previousElement = $element
            foreach ($childNode in $childNodes) { 
                $importNode = $element.OwnerDocument.ImportNode($childNode, $true)
                $element.ParentNode.InsertAfter($importNode, $previousElement)
                $previousElement = $importNode
            }
        }
        else {
            throw "XPath could not be found ($xpath)."
        }
    }
}

function InsertBefore {
    param([Xml.XmlDocument]$document, [string]$xpathExists, [string]$xpath, [string]$content)
    [Xml.XmlElement]$elementExists = $document.SelectSingleNode($xpathExists)
    if ($elementExists -eq $null) {
        [Xml.XmlElement]$element = $document.SelectSingleNode($xpath)
        if ($element -ne $null) {
            Write-Verbose "Insert child nodes."
            $newelement = [xml]"<dummy xml:space='preserve'>$content</dummy>"
            $childNodes = $newelement.DocumentElement.ChildNodes
            $previousElement = $element
            foreach ($childNode in $childNodes) { 
                $importNode = $element.OwnerDocument.ImportNode($childNode, $true)
                $element.ParentNode.InsertBefore($importNode, $previousElement)
                $previousElement = $importNode
            }
        }
        else {
            throw "XPath could not be found ($xpath)."
        }
    }
}

function RemoveChild {
    param([Xml.XmlDocument]$document, [string]$xpath)
    [Xml.XmlElement]$element = $document.SelectSingleNode($xpath)
    if ($element -ne $null) {
        Write-Verbose "Remove child node."
        $element.ParentNode.RemoveChild($element)
    }
}
