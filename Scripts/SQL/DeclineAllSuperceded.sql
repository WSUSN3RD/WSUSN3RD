/****************************************************************************** 
Declines ALL superceded updates in the SUSDB.
Thanks to Vinay Pamnani for this script. 
Ideally, you'd run the PowerShell script first, but if you're having timeout issues, this script is an option. 
Fill in domain\user with an account in the WSUS Admins group. 

******************************************************************************/ 

DECLARE @var1 uniqueidentifier 
DECLARE @msg nvarchar(100) 
declare DU Cursor
For
Select UpdateID from vwMinimalUpdate where IsSuperseded =1
Open DU
Fetch next From DU
into @var1
WHILE (@@FETCH_STATUS > -1) 
BEGIN 
--SET @msg = 'Declining' + CONVERT(varchar(100), @var1) 
--print @msg
RAISERROR(@msg,0,1) WITH NOWAIT exec spDeclineUpdate @updateID=@var1,@adminName=N'domain\user',@failIfReplica=1
FETCH NEXT FROM DU INTO @var1 END 
CLOSE DU 
DEALLOCATE DU

