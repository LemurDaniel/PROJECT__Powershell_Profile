function Get-DailyMsRewards {
    param()
 
    Get-MsRewards -calls 20 -browser Chrome # User-Agent Switcher set to Android for Mobile-Searches
    Get-MsRewards -calls 30 -browser Opera

}