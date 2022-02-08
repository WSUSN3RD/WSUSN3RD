-- Finds updates that were manually imported into the SUSDB from catalog.update.microsoft.com
-- Feel free to update the query to be more efficent if you'd like
-- Change LanguageID as needed

select
 uf.FromCatalogSite as FromCatalog,
 lp.Title,
 u.UpdateID, 
 u.LocalUpdateID,
 r.RevisionID,
 pr.CreationDate,
 u.ImportedTime,
 r.IsLatestRevision
from 
 tbUpdateflag uf
 inner join tbUpdate u on uf.LocalUpdateID  = u.LocalUpdateID
 inner join tbRevision r on u.LocalUpdateID = r.LocalUpdateID 
 inner join tbProperty pr on pr.RevisionID = r.RevisionID 
 inner join tbLocalizedPropertyForRevision lpr on r.RevisionID = lpr.RevisionID 
 inner join tbLocalizedProperty lp on lpr.LocalizedPropertyID = lp.LocalizedPropertyID 
where 
lpr.LanguageID = 1033 and IsLatestRevision =1 and uf.FromCatalogSite =1
