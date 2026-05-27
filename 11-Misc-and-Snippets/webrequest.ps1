Import-Module -Name Selenium

$ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver
$ChromeDriver.Navigate().GoToURL('https://www.relojlaboral.com/login.php?')


$ChromeDriver.FindElementByXPath('//*[@id="top"]/div/nav/div/div/div/div[1]/button/i').Click()
Start-Sleep -Seconds 3
$ChromeDriver.FindElementByXPath('//*[@id="top"]/div/nav/div/div/div/div[2]/ul/li[7]/a').Click()
Start-Sleep -Seconds 3
$ChromeDriver.FindElementByXPath('//*[@id="account"]').SendKeys('user@contoso.com')
$ChromeDriver.FindElementByXPath('//*[@id="password"]').SendKeys('crebOrd2')
$ChromeDriver.FindElementByXPath('//*[@id="login"]/input[3]').Click()
Start-Sleep -Seconds 3
$ChromeDriver.FindElementByXPath('//*[@id="accion"]').Click()
$ChromeDriver.FindElementByXPath('//*[@id="tab_hoy"]').Click()
Start-Sleep -Seconds 3
$ChromeDriver.SwitchTo().Alert().Accept()
$fichajes= (Find-SeElement -Driver $ChromeDriver -Id registro_hoy).Text
$fichajes | Out-File C:\temp\fichaje.txt



$ChromeDriver.Close()
$ChromeDriver.Quit()

