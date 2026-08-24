Function New-Starter
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        #[ValidatePattern('^[A-Za-z]+$')]
        [STRING]$FirstName,
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [STRING]$LastName,
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('HR','Sales','Media','IT','Legal','Compliance','Network','Service Delivery','Facilities','Finance')]
        [STRING]$Department,
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        #[ValidatePattern('^[0-9][0-9-]*$')]
        [STRING]$PasswordLength, #Set password as string to allow my script to detect characer and speical character and generate a user friendly message
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        #[ValidatePattern('^[0-9][0-9-]*$')]
        [STRING]$TelNumber, #must be a string to allow users to type 0 at the beginning
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        #[ValidatePattern('^[0-9]+(-[0-9]+)*$')]
        [STRING]$MobileNumber, #must be a string to allow users to type 0 at the beginning
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        #[ValidatePattern('^[A-Za-z]+(?: [A-Za-z]+)*$')]
        [STRING]$JobTitle,
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [STRING]$ManagerFullName,
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [STRING]$CloneUser
    )

    begin
    {
        $AllStaffGroup = "All Staff"
        $Company = "ITPro Guide"
        $Office = "London"
        $Street = "402 King Road"
        $PostalCode = "SW10 0LJ"

    }
    Process
    {
        #Check variables are entered correctly before the acount is created

        #Check if no characters or special characters are entered
         if($PasswordLength -notmatch '^\d+$')
        {
            Write-Warning "You must enter digits only"
            return
        }

        #Check that the user enter minimum of 10 characters
        if([int]$PasswordLength -lt 10)
        {
            Write-Warning "You need minimum of 10 characters"
            return
        }
        
        #Check Firstname only has letters
        if($FirstName -notmatch '^[A-Za-z]+$')
        {
            Write-Warning "Please enter only letters and no numbers or special characters"
            return
        }
        if($LastName -notmatch '^[A-Za-z]+[0-9]*$')
        {
            Write-Warning "You must enter letters with numbers allowed at the end"
            return
        }
        #Validate Telephone number and make sure the telephone number contains only numbers or hypens and maximum of 13 characters long
        if($TelNumber -notmatch '^0[0-9-]+$' -and $TelNumber -le 13)
        {
            Write-Warning "Telephone number must start with 0 and contain numbers or hyphens only and must be 13 characters long"
            return
        }

        #Validate Telephone number and make sure the telephone number contains 07 at the beginning, only numbers and maximum of 11 characters long
        if($MobileNumber -notmatch '^07[0-9]{9}$')
        {
            Write-Warning "Mobile number must start with 0 and contain numbers or hyphens only and must be 13 characters long"
            return
        }
        
        #Check that Job Title only has characters and no numbers or special characters
        if($JobTitle -notmatch '^[A-Za-z ]+$')
        {
            Write-Warning "Please enter only letters and no numbers or special characters for the job title"
            return
        }

        $UpperCaseFirstname = (Get-Culture).TextInfo.ToTitleCase($FirstName.ToLower()) #Convert first letter of the firstname to uppsercase
        $UpperCaseLastname = (Get-Culture).TextInfo.ToTitleCase($LastName.ToLower()) #Convert first letter of the firstname to uppsercase

        $DisplayName = $UpperCaseLastname+" "+$UpperCaseFirstname #Put lastname and firstname in display name
        $Name = $UpperCaseFirstname+" "+$UpperCaseLastname #Combine firstname and lastname together
        

        #convert name and email address into SAMAccountName and UPN. UPN is the same as email address
        $UserName = "$UpperCaseLastname$($UpperCaseFirstname[0])"
        $UPN = "$($UpperCaseFirstname[0]).$UpperCaseLastname@contoso.com"
        $EmailAddress = $UPN

        $UserDetails = @()

        #Generate Password
        $Length = 16

        $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
        $lower = 'abcdefghijkmnopqrstuvwxyz'
        $numbers = '0123456789'
        $special = '!@#$%&*?'

        $all = $upper + $lower + $numbers +$special

        #Generate Random characters from each variable
        $RandomPassword = @(
            $upper[(Get-Random -Maximum $upper.Length)]
            $lower[(Get-Random -Maximum $lower.Length)]
            $numbers[(Get-Random -Maximum $numbers.Length)]
            $special[(Get-Random -Maximum $special.Length)]
        )

        #Generate more random characters based on Password Lenght size and add it into an array
        while ($RandomPassword.Count -lt $PasswordLength)
        {
            $RandomPassword += $all[(Get-Random -Maximum $all.Length)]
        }

        #Murge the array into one large entry
        $password = -join ($RandomPassword | sort {Get-Random})
        



        #Get all required groups to add
        

        $DepartmentGroup = ""
        $OUPath = ""
        $SecurityGroup = ""
        switch($Department)
        {
            "HR"
            {
                $OUPath = "OU=HR,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="HR Team"
                $SecurityGroup = "HR RW"
            }
            "Sales"
            {
                $OUPath = "OU=Sales,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Sales Team"
                $SecurityGroup = "Sales RW"
            }
            "Media"
            {
                $OUPath = "OU=Media,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Media Team"
                $SecurityGroup = "Media RW"
            }
            "IT" 
            {
                $OUPath = "OU=IT,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="IT Team"
                $SecurityGroup = "IT RW"
            }
            "Legal"
            {
                $OUPath = "OU=Legal,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Legal Team"
                $SecurityGroup = "Legal RW"
            }
            "Compliance"
            {
                $OUPath = "OU=Compliance,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Compliance Team"
                $SecurityGroup = "Compliance RW"
            }
            "Network" 
            {
                $OUPath = "OU=Network,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Network Team"
                $SecurityGroup = "Network RW"
            }
            "Service Delivery" 
            {
                $OUPath = "OU=Service Delivery,OU=MS102Project,OU=IPG,DC=contoso,DC=com" 
                $DepartmentGroup="Service Delivery Team"
                $SecurityGroup = "Service Delivery RW"
            }
            "Facilities" 
            {
                $OUPath = "OU=Facilities,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Facilities Team"
                $SecurityGroup = "Facilities Team RW"
            }
            "Finance" 
            {
                $OUPath = "OU=Finance,OU=MS102Project,OU=IPG,DC=contoso,DC=com"
                $DepartmentGroup="Finance Team"
                $SecurityGroup = "Finance Team RW"
            }   
        }
        #Add Manager to the account if the parameter is used

        if(-not [string]::IsNullOrWhiteSpace($ManagerFullName))
        {
            $ManagerUserName = (Get-ADUser -Properties Name -Filter * | where{$_.Name -eq $ManagerFullName}).SamAccountName
        }

        #Check if user exist in AD
        if(([ADSISearcher] "(sAmAccountName=$UserName)").FindOne())
        {
            #If an account exist generate an error and stop the code by using return
            Write-Warning "User Account Exist"
            return
        }

        #Create the user account in AD
        New-ADUser -GivenName $UpperCaseFirstname `
        -Surname $UpperCaseLastname `
        -Name $Name `
        -DisplayName $DisplayName `
        -UserPrincipalName $UPN `
        -SamAccountName $UserName `
        -EmailAddress $EmailAddress `
        -Department $Department `
        -Path $OUPath `
        -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
        -Title $JobTitle `
        -MobilePhone $MobileNumber `
        -OfficePhone $TelNumber `
        -Manager $ManagerUserName `
        -HomePhone $TelNumber `
        -Company $Company `
        -Office $Office `
        -StreetAddress $Street `
        -City $Office `
        -PostalCode $PostalCode `
        -Enabled $true
        
       #Wait for account to create and move on to the next part of the script
        Start-Sleep -Seconds 3

        #Add user to the groups
        $AllGroups = @($AllStaffGroup, $DepartmentGroup, $SecurityGroup)
        
        foreach($Group in $AllGroups)
        {

            Add-ADPrincipalGroupMembership -Identity $UserName -MemberOf $Group
        }

        #Get clone user and groups
        if(-not [string]::IsNullOrWhiteSpace($CloneUser))
        {
            #Get username

            $CloneUsername = (Get-ADUser -filter * | where{$_.Name -eq $CloneUser}).SamAccountName

            #Generate an error if CloneUsername is empty

            if([string]::IsNullOrWhiteSpace($CloneUsername))
            {
                Write-Warning "Please enter correct Name for cloning a user profile"
                return
            }

            if($UserName -match $CloneUsername)
            {
                Write-Warning "Please do not use the same account you have created"
                $UserDetails
                return
            }

            #Get list of groups, exclude groups that already added and add the groups into new starter account
            

            $UserGroups = Get-ADPrincipalGroupMembership -Identity $CloneUsername | where{$_.Name -ne $DepartmentGroup} | where{$_.Name -ne $SecurityGroup} | where{$_.Name -ne $AllStaffGroup} | where{$_.Name -ne "Domain Users"} | select SamAccountName #Get all the groups from clone user account and exclude the groups that are already been added

            foreach($ug in $UserGroups)
            {
                Add-ADPrincipalGroupMembership -Identity $UserName -MemberOf $ug #add the groups to new starter
            }
            
        }

        #Store details into an array
        $User = Get-ADUser -Identity $UserName -Properties Department, PasswordLastSet, OfficePhone, MobilePhone, Title, EmailAddress, Manager
        $UserDetails += [PSCustomObject]@{
            Firstname = $User.GivenName
            Lastname = $User.Surname
            Username = $user.SamAccountName
            EmailAddress = $user.EmailAddress
            Password = $password
            OfficeNumber = $user.OfficePhone
            MobilePhone = $user.MobilePhone
            Department = $User.Department
            JobTitle = $user.Title
            Manager = $user.Manager
            CloneUser = $CloneUser
            WhenPasswordCreated = $user.PasswordLastSet
        }
    }
    End
    {
        #Output details
        $UserDetails
    }
}