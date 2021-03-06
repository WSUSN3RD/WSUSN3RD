
-- ConfigMgr's default for client reporting to the WSUS is status only. 
-- ConfigMgr has this in the site control file PROPERTY <ClientReportingLevel><><><0> under COMPONENT=<SMS_WSUS_CONFIGURATION_MANAGER>
-- If you flop back to a 'WSUS only' environment your clients dont send the original level of detail
-- You can change the ClientReportingLevel in SUSDB to fix this. 
-- 0 is none, 1 is status only, 2 is all reporting events (WSUS default w/o ConfigMgr)
-- UPDATE tbConfiguration SET ClientReportingLevel = 2
SELECT * FROM [dbo].[tbConfiguration] where Name = 'ClientReportingLevel' 


-- WSUS can support upto 100k clients assuming server has enough umph, not a ton of updates, and clients aren't scanning like crazy all the time.
-- However, you need to bump the max from the default of 20k/30k to support this. 
-- UPDATE tbConfigurationC SET MaxTargetComputers = 100000
SELECT MaxTargetComputers FROM [SUSDB].[dbo].[tbConfigurationC] 


-- When client gets Error:	WU_E_PT_EXCEEDED_MAX_SERVER_TRIPS
-- Client will eventually finish scanning, it just needs multitiple scans to actually get all the metadata it requires.
-- Sometimes this is more than 2 scans and you don't want to wait, espcially when scan schedule is like every 7 days or so. 
-- Make the MaxXMLPerRequest unlimited. Perf may take a hit when a ton of clients are doing a full scan with this setting. 
-- UPDATE tbConfigurationC SET MaxXMLPerRequest = 0
SELECT MaxXMLPerRequest FROM [SUSDB].[dbo].[tbConfigurationC] 

--WSUS cleanup needed? Queries to help determine this: 
select count (*) from vwMinimalUpdate where IsSuperseded =1 and Declined ='0' 
select count (*) from vwMinimalUpdate where IsSuperseded =1 and Declined ='1' 
select count (*) from vwMinimalUpdate 
--So, that will give you 1) number of superseded updates that are not declined 2) number of declined superseded updates 3) total number of explicitly deployable updates
-- Based on these numbers, you can make a really good judgement call on if they are actually declining updates in a reasonable fashion. Just compare the numbers
EXEC spGetObsoleteUpdatesToCleanup  
--this number should not be very high
