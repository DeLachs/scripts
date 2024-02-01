$global:domain_user = ""
$global:domain = ""
$global:domain_controller = ""
$organizational_units = @()
$ou_to_join = ""
$new_pc_name = ""

$button_query_click = {
    # set the vars
    $global:domain_controller = $TextBoxAdminLoginDC.Text
    $global:domain = $TextBoxAdminLoginDomain.Text
    $global:domain_user = $TextBoxAdminLoginUser.Text
    # query ad
    try {
        $organizational_units += Invoke-Command -ComputerName $domain_controller -Authentication Kerberos -Credential $domain\$domain_user -ScriptBlock {
            $get_adou_output = Get-ADOrganizationalUnit -Filter 'Name -like "*"'
            return $get_adou_output
        } -ErrorAction stop

        Foreach ($unit in $organizational_units) {
            $ComboBoxOUs.Items.Add($unit)
        }

        # enable button to join pc to ad
        $ButtonJoinAD.Enabled = $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to query AD.","Error",[System.Windows.MessageBoxButton]::Ok,[System.Windows.MessageBoxImage]::Error)
    }
}


$button_join_ad_click = {
    $ou_to_join = $ComboBoxOUs.SelectedItem
    $new_pc_name = $TextBoxNewPCName.Text

    $result_confirmation = [System.Windows.Forms.MessageBox]::Show("The PC will join the domain: '$domain' in the OU: '$ou_to_join' with the name: '$new_pc_name' and will restart immediately.","Warning",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)

    if ($result_confirmation -eq "Yes") {
        try {
            Add-Computer -DomainName $domain -Credential $domain\$domain_user -ComputerName $env:computername -OUPath $ou_to_join -NewName $new_pc_name  -Restart -Force
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to join domain '$domain'.","Error",[System.Windows.MessageBoxButton]::Ok,[System.Windows.MessageBoxImage]::Error)
        }
    } else {}
}


Add-Type -AssemblyName System.Windows.Forms

$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "Domain Join Champ"
$main_form.AutoSize = $true

$LabelAdminLoginDC = New-Object System.Windows.Forms.Label
$LabelAdminLoginDC.Text = "Domain Controller (dc1.example.com):"
$LabelAdminLoginDC.Location = New-Object System.Drawing.Point(10,10)
$LabelAdminLoginDC.AutoSize = $true
$main_form.Controls.Add($LabelAdminLoginDC)

$TextBoxAdminLoginDC = New-Object System.Windows.Forms.TextBox
$TextBoxAdminLoginDC.Location = New-Object System.Drawing.Point(10,30)
$TextBoxAdminLoginDC.Size = New-Object System.Drawing.Size(250,30)
$main_form.Controls.Add($TextBoxAdminLoginDC)

$LabelAdminLoginDomain = New-Object System.Windows.Forms.Label
$LabelAdminLoginDomain.Text = "Domain (example.com):"
$LabelAdminLoginDomain.Location = New-Object System.Drawing.Point(10,60)
$LabelAdminLoginDomain.AutoSize = $true
$main_form.Controls.Add($LabelAdminLoginDomain)

$TextBoxAdminLoginDomain = New-Object System.Windows.Forms.TextBox
$TextBoxAdminLoginDomain.Location = New-Object System.Drawing.Point(10,80)
$TextBoxAdminLoginDomain.Size = New-Object System.Drawing.Size(115,30)
$main_form.Controls.Add($TextBoxAdminLoginDomain)

$LabelAdminLoginUser = New-Object System.Windows.Forms.Label
$LabelAdminLoginUser.Text = "User:"
$LabelAdminLoginUser.Location = New-Object System.Drawing.Point(150,60)
$LabelAdminLoginUser.AutoSize = $true
$main_form.Controls.Add($LabelAdminLoginUser)

$TextBoxAdminLoginUser = New-Object System.Windows.Forms.TextBox
$TextBoxAdminLoginUser.Location = New-Object System.Drawing.Point(150,80)
$TextBoxAdminLoginUser.Size = New-Object System.Drawing.Size(110,30)
$main_form.Controls.Add($TextBoxAdminLoginUser)

$ButtonQuery = New-Object System.Windows.Forms.Button
$ButtonQuery.Text = "Query AD"
$ButtonQuery.Location = New-Object System.Drawing.Point(10,110)
$ButtonQuery.Size = New-Object System.Drawing.Size(75,23)
$ButtonQuery.Add_Click($button_query_click)
$main_form.Controls.Add($ButtonQuery)

$LabelOUs = New-Object System.Windows.Forms.Label
$LabelOUs.Text = "Active Directory OUs"
$LabelOUs.Location = New-Object System.Drawing.Point(10,150)
$LabelOUs.AutoSize = $true
$main_form.Controls.Add($LabelOUs)

$ComboBoxOUs = New-Object System.Windows.Forms.ComboBox
$ComboBoxOUs.Location = New-Object System.Drawing.Point(10,170)
$ComboBoxOUs.Width = 250
$main_form.Controls.Add($ComboBoxOUs)

$LabelNewPCName = New-Object System.Windows.Forms.Label
$LabelNewPCName.Text = "New PC name:"
$LabelNewPCName.Location = New-Object System.Drawing.Point(10,200)
$LabelNewPCName.AutoSize = $true
$main_form.Controls.Add($LabelNewPCName)

$TextBoxNewPCName = New-Object System.Windows.Forms.TextBox
$TextBoxNewPCName.Location = New-Object System.Drawing.Point(10,220)
$TextBoxNewPCName.Width = 250
$main_form.Controls.Add($TextBoxNewPCName)

$ButtonJoinAD = New-Object System.Windows.Forms.Button
$ButtonJoinAD.Text = "Join AD"
$ButtonJoinAD.Location = New-Object System.Drawing.Point(10,250)
$ButtonJoinAD.Size = New-Object System.Drawing.Size(75,23)
$ButtonJoinAD.Add_Click($button_join_ad_click)
$ButtonJoinAD.Enabled = $false
$main_form.Controls.Add($ButtonJoinAD)

$main_form.ShowDialog()
