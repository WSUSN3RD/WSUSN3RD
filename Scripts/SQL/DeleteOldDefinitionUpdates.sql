-- Deletes DECLINED updates that are in the Definition Updates classification from the susdb
-- This is useful if your WSUS server hasn't been syncing for while and the expiration of the def updates currently in the susdb were missed
-- Decline the definition updates, then run this script against the susdb

DECLARE @var1 uniqueidentifier
DECLARE @msg nvarchar(100)

CREATE TABLE #results (Col1 uniqueidentifier)

INSERT INTO #results(Col1) select updateid from  [PUBLIC_VIEWS].[vUpdate] where IsDeclined = 1 and 
ClassificationId = (select ClassificationId from PUBLIC_VIEWS.vClassification where defaulttitle = 'Definition Updates')

DECLARE WC Cursor
FOR

SELECT Col1 FROM #results
OPEN WC
FETCH NEXT FROM WC
INTO @var1

WHILE (@@FETCH_STATUS > -1)
BEGIN SET @msg = 'Deleting ' + CONVERT(nvarchar(100), @var1)

RAISERROR(@msg,0,1) WITH NOWAIT EXEC spDeleteUpdatebyupdateid @var1

FETCH NEXT FROM WC INTO @var1 END
CLOSE WC
DEALLOCATE WC

DROP TABLE #results
