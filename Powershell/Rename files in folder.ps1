
clear

$dirPath = 'C:\Users\sgimu\Downloads'

#Regex to replace matches
$regex2 = '(?i)\s*(?:\-|\—|\–|\–)?\s*(?:P\w{3}samson\.?com)'



#--See Matches
<#
dir -Path $dirPath | where { (Get-Item $_.FullName).IsReadOnly -eq 0} | Foreach {if ( $_.Name.Trim() -match $regex2){
                                                                                                            $_.Name
                                                                                                            $Matches[0]
                                                                                                            $Matches[1]
                                                                                                        }
                                                                                                        
                                                                                                        #Using .NET regex class   
                                                                                                        #$_.Name
                                                                                                        #[regex]::Match($_.Name.Trim(), $regex).Groups[1].Value
                                                                                                    }
                                                                                                    #>
#--Do Replacement
dir -Path $dirPath | where {(Get-Item -literalpath $_.FullName).IsReadOnly -eq 0} | foreach { Rename-Item -literalpath $_.FullName -NewName ($_.Name -replace $regex2, '') }


#Notes
#1. We use -LiteralPath because without it powershell won't pick filenames containing square brackets ([])