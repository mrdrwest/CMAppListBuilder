#region UI runspace
$syncHash = [hashtable]::Synchronized(@{})
$uiRunspace = [runspacefactory]::CreateRunspace()
$uiRunspace.ApartmentState = "STA"
$uiRunspace.ThreadOptions = "ReuseThread"
$uiRunspace.Open()
$uiRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
$poshCmd = [PowerShell]::Create().AddScript({

    #region Variables
    $listboxTitle = "ConfigMgr Application Model List"
    $statusMsg = "Status: "
    $applist = @()
    #endregion

    #region WPF Window
    $syncHash.ApplicationList = New-Object Windows.Window
    $syncHash.ApplicationListButtons = New-Object Windows.Controls.Button
    $syncHash.ApplicationList.SizeToContent = "WidthAndHeight"
    $syncHash.ApplicationList.Title = "ApplicationListBuilder"
    #endregion

    #region WPF Label
    $syncHash.labelListBoxTitle = New-Object Windows.Controls.Label
    $syncHash.labelListBoxTitle.Content = $listboxTitle
    $syncHash.labelStatus = New-Object Windows.Controls.Label
    $syncHash.labelStatus.Content = $statusMsg
    #endregion

    #region WPF ListBox
    $syncHash.listboxApplications = New-Object Windows.Controls.ListBox
    $syncHash.listboxApplications.Width = 480
    $syncHash.listboxApplications.Height = 250
    $syncHash.listboxApplications.SelectionMode = "Extended"
    $syncHash.listboxApplications.Sorted = $True

    #region WPF Button
    $syncHash.buttonSCCMDynamicVariable = New-Object Windows.Controls.Button
    $syncHash.buttonSCCMDynamicVariable.Content = "Add"
    #endregion
    
    $syncHash.buttonSCCMDynamicVariable.Add_Click({
        #$syncHash.listboxApplications.ItemsSource = @($applist)
        $syncHash.labelStatus.Dispatcher.Invoke([action]{ $syncHash.labelStatus.Content = $statusMsg+"Added selected applications to dynamic variable list" }, "Normal")
    })

    #region Display Window
    $syncHash.stackPanel = New-Object Windows.Controls.StackPanel
    $syncHash.syncHash.Orientation="Vertical"
    $syncHash.children = $syncHash.labelListBoxTitle, $syncHash.listboxApplications, $syncHash.labelStatus, $syncHash.buttonSCCMDynamicVariable
    foreach ($child in $syncHash.children) { $null = $syncHash.stackPanel.Children.Add($child) }
    $syncHash.ApplicationList.Content = $syncHash.stackPanel
    #$null = $syncHash.ApplicationList.ShowDialog()
    $syncHash.ApplicationList.ShowDialog() | Out-Null
    #$syncHash.Error = $Error
    })
    #endregion

    #region Invoke separate UI runspace
    $poshCmd.Runspace = $uiRunspace
    $data = $poshCmd.BeginInvoke()
    #endregion

    Start-Sleep -Seconds 5

    #region Query SMS Provider for the list of applications and update the Status: label control in the separate UI runspace
    $syncHash.labelStatus.Dispatcher.Invoke([action]{ $syncHash.labelStatus.Content = "Status: Querying SMS Provider" }, "Normal")
    #$applist = (Get-CimInstance SMS_Application -Namespace root\sms\site_CAS -computername server | where {($_.LocalizedDisplayName -match "ISP1_") -and ($_.IsLatest)}).LocalizedDisplayName
    $applist = "Placeholder*******"
    $syncHash.listboxApplications.Dispatcher.Invoke([action]{ $syncHash.listboxApplications.ItemsSource = @($applist | sort) }, "Normal")
    $syncHash.labelStatus.Dispatcher.Invoke([action]{ $syncHash.labelStatus.Content = "Status: Ready" }, "Normal")
    #endregion