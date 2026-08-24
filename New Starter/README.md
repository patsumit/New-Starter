# New-Starter

`New-Starter` is a PowerShell onboarding function for creating and
provisioning new user accounts in an on-premises Active Directory lab.

The project automates repetitive new-starter administration by
validating employee data, generating account details and a temporary
password, selecting the correct department OU and groups, assigning an
optional manager, optionally cloning additional group memberships from
an existing user, and returning the created account as structured
PowerShell output.

> **Lab domain in this GitHub version:** `contoso.com`

## Features

-   Creates enabled Active Directory user accounts.
-   Generates `SamAccountName`, UPN, email address, display name, and a
    random temporary password.
-   Validates first name, last name, password length, telephone number,
    mobile number, and job title.
-   Maps departments to the appropriate OU, department group, and
    security group.
-   Adds every new starter to the `All Staff` group.
-   Supports optional manager assignment.
-   Detects an existing `SamAccountName` before account creation.
-   Supports optional cloning of additional AD group memberships from
    another user.
-   Excludes baseline groups and `Domain Users` when cloning access.
-   Returns a `[PSCustomObject]` containing the new account details.
-   Supports CSV-driven bulk onboarding through PowerShell.

## Requirements

This script is designed for an Active Directory lab or test environment.
It requires:

-   Active Directory Domain Services.
-   The Active Directory PowerShell module / RSAT.
-   Permission to create users, read users, and modify group
    memberships.
-   The OUs and groups referenced in the script to exist before
    execution.

If required:

``` powershell
Import-Module ActiveDirectory
```

## Parameters

  -----------------------------------------------------------------------
  Parameter               Required                Purpose
  ----------------------- ----------------------- -----------------------
  `FirstName`             Yes                     User's first name.

  `LastName`              Yes                     User's surname.

  `Department`            Yes                     Selects the user's OU
                                                  and baseline department
                                                  groups.

  `PasswordLength`        No                      Requested generated
                                                  password length; the
                                                  script validates digits
                                                  and a minimum of 10.

  `TelNumber`             No                      Landline number stored
                                                  as a string so a
                                                  leading zero can be
                                                  preserved.

  `MobileNumber`          No                      UK-style mobile number;
                                                  current validation
                                                  expects `07` followed
                                                  by nine digits.

  `JobTitle`              Yes                     User's job title.

  `ManagerFullName`       No                      Full name used to
                                                  resolve and assign the
                                                  user's manager.

  `CloneUser`             No                      Full name of an
                                                  existing user whose
                                                  additional group
                                                  memberships should be
                                                  copied.
  -----------------------------------------------------------------------

The `Department` parameter currently accepts:

`HR`, `Sales`, `Media`, `IT`, `Legal`, `Compliance`, `Network`,
`Service Delivery`, `Facilities`, and `Finance`.

## Account Naming Convention

For a user named **Thomas Green**, the script generates:

``` text
Name: Thomas Green
Display name: Green Thomas
SamAccountName: GreenT
UPN: T.Green@contoso.com
Email address: T.Green@contoso.com
```

The UPN/email convention is:

``` text
FirstInitial.LastName@contoso.com
```

## Input Validation

Before account creation, the function performs several checks:

-   `PasswordLength` must contain digits only and must be at least 10.
-   `FirstName` must contain letters only.
-   `LastName` must begin with letters; the current rule allows optional
    numbers at the end.
-   `TelNumber` must follow the landline validation implemented in the
    script.
-   `MobileNumber` must match the current UK mobile pattern:
    `^07[0-9]{9}$`.
-   `JobTitle` permits letters and spaces.
-   `Department` is restricted with `ValidateSet`.
-   The proposed `SamAccountName` is checked in AD before the user is
    created.
-   If a clone user is requested, the function checks whether that user
    can be resolved.

When a validation check fails, the function writes a warning and stops
processing that user.

## Department and Group Provisioning

The selected department controls three important provisioning values:

1.  The target Organizational Unit.
2.  The department team group.
3.  The department read/write security group.

Every user is also assigned to:

``` text
All Staff
```

Example for IT:

``` text
OU=IT,OU=MS102Project,OU=IPG,DC=contoso,DC=com
IT Team
IT RW
All Staff
```

The `OU=IPG` and `OU=MS102Project` structure has intentionally been
retained from the original lab. Change these OUs if your own test
environment uses a different hierarchy.

## Password Generation

The function creates a random temporary password using separate
character pools for:

-   Uppercase letters.
-   Lowercase letters.
-   Numbers.
-   Special characters.

It first selects at least one character from each pool, adds random
characters until the requested length is reached, shuffles the character
array, and joins it into a single password.

The password is converted to a `SecureString` when supplied to
`New-ADUser`.

## Manager Assignment

`ManagerFullName` is optional.

When supplied, the function searches Active Directory for the manager's
name and obtains the manager's `SamAccountName`, which is then supplied
to `New-ADUser`.

This supports a staged bulk-onboarding process where managers can be
created first and staff members afterward.

## Clone User

`CloneUser` is optional.

When a clone user is supplied, the function:

1.  Resolves the clone user's `SamAccountName`.
2.  Warns and stops if the clone user cannot be found.
3.  Prevents the new account from being used as its own clone source.
4.  Retrieves the clone user's group memberships.
5.  Excludes the new starter's baseline department group, security
    group, `All Staff`, and `Domain Users`.
6.  Adds the remaining group memberships to the new starter.

This allows role-related access to be copied while retaining the
department-specific access assigned by the onboarding workflow.

## Example: Create One New Starter

``` powershell
New-Starter `
    -FirstName "Thomas" `
    -LastName "Green" `
    -Department "IT" `
    -PasswordLength 12 `
    -TelNumber "02079460016" `
    -MobileNumber "07700900016" `
    -JobTitle "IT Support Engineer" `
    -ManagerFullName "Ethan Clarke"
```

## Example: Clone Additional Access

``` powershell
New-Starter `
    -FirstName "Ava" `
    -LastName "Mitchell" `
    -Department "IT" `
    -PasswordLength 12 `
    -TelNumber "02079460017" `
    -MobileNumber "07700900017" `
    -JobTitle "Systems Administrator" `
    -ManagerFullName "Ethan Clarke" `
    -CloneUser "Thomas Green"
```

## Bulk Onboarding from CSV

A CSV can contain fields matching the function parameters:

``` csv
FirstName,LastName,Department,TelNumber,MobileNumber,JobTitle,ManagerFullName
Olivia,Bennett,HR,02079460001,07700900001,HR Manager,Sumit Patel
Emily,Parker,HR,02079460011,07700900011,HR Advisor,Olivia Bennett
```

One useful approach is to provision managers first and then their staff:

``` powershell
$ManagerMembers = Import-Csv ".\MS102_New-Starters.csv" |
    Where-Object { $_.ManagerFullName -eq "Sumit Patel" }

foreach ($Member in $ManagerMembers)
{
    New-Starter `
        -FirstName $Member.FirstName `
        -LastName $Member.LastName `
        -Department $Member.Department `
        -PasswordLength 12 `
        -TelNumber $Member.TelNumber `
        -MobileNumber $Member.MobileNumber `
        -JobTitle $Member.JobTitle `
        -ManagerFullName $Member.ManagerFullName
}

Start-Sleep -Seconds 3

$StaffMembers = Import-Csv ".\MS102_New-Starters.csv" |
    Where-Object { $_.ManagerFullName -ne "Sumit Patel" }

foreach ($Member in $StaffMembers)
{
    New-Starter `
        -FirstName $Member.FirstName `
        -LastName $Member.LastName `
        -Department $Member.Department `
        -PasswordLength 12 `
        -TelNumber $Member.TelNumber `
        -MobileNumber $Member.MobileNumber `
        -JobTitle $Member.JobTitle `
        -ManagerFullName $Member.ManagerFullName
}
```

The two-pass approach ensures that department managers exist in Active
Directory before staff accounts attempt to reference them.

## Output

After provisioning, the function queries the new AD account and returns
a `[PSCustomObject]` containing:

-   First name.
-   Last name.
-   Username.
-   Email address.
-   Generated temporary password.
-   Office number.
-   Mobile number.
-   Department.
-   Job title.
-   Manager.
-   Clone user.
-   Password creation timestamp.

Because the result is a PowerShell object, it can be piped to other
commands or exported:

``` powershell
$Result = New-Starter @Parameters
$Result | Format-Table
```

``` powershell
$Result | Export-Csv ".\NewStarterResults.csv" -NoTypeInformation
```

## Workflow

``` text
Employee / CSV data
        |
        v
Validate input
        |
        v
Generate identity + temporary password
        |
        v
Map department to OU and groups
        |
        v
Resolve optional manager
        |
        v
Check for duplicate account
        |
        v
Create AD user
        |
        v
Assign baseline groups
        |
        v
Clone optional additional access
        |
        v
Return structured account result
```

## Security Notes

This repository represents a learning/lab project.

The current function returns the generated temporary password as part of
its output. Do not commit generated passwords, real employee data,
production credentials, or exported onboarding results containing
passwords to a public repository.

Before adapting the project for production, review your organisation's
requirements for privileged access, password delivery, logging,
auditing, error handling, least privilege, access approvals,
duplicate-name handling, and protection of onboarding data.

## What This Project Demonstrates

This project provides practical examples of:

-   Advanced PowerShell functions.
-   Parameters and pipeline-aware parameter binding.
-   `begin`, `process`, and `end`.
-   Regular expressions.
-   Input validation.
-   Conditional logic.
-   `switch`.
-   Arrays and `foreach`.
-   Active Directory cmdlets.
-   ADSI searching.
-   Random password generation.
-   String manipulation.
-   `SecureString`.
-   AD group membership management.
-   `[PSCustomObject]`.
-   CSV-driven bulk automation.

## Disclaimer

This project is intended for learning and lab use. Test PowerShell
automation thoroughly in a non-production environment before adapting it
for production Active Directory.
