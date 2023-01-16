function Get-DailyMsRewards {
    param()
 
    Get-MsRewards -calls 21 -browser Chrome
    Get-MsRewards -calls 4 -browser Edge
    Get-MsRewards -calls 30 -browser Opera

}