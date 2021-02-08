
# Load administration
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration') | out-null

$filename="c:\cat.txt"
"Script Started" | out-file -filepath $filename

# Create update server
"<<< Connecting to WSUS server >>>" | out-file -filepath $filename -append
$updateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()

# Get all categories
 "<<< Getting all categories >>>" | out-file -filepath $filename -append
$categories = $updateServer.GetUpdateCategories()

# Print out the local 'Company' categories
 "<<< Dumping locally published company categories >>>" | out-file -filepath $filename -append
" Company categories " | out-file -filepath $filename -append
" ================== " | out-file -filepath $filename -append
"" | out-file -filepath $filename -append
$i = 1
foreach ($category in $categories)
{
  if ($category.Type -eq [Microsoft.UpdateServices.Administration.UpdateCategoryType]::Company)
  {
    if ($category.UpdateSource -eq [Microsoft.UpdateServices.Administration.UpdateSource]::Other)
    {
      "  Category # $($i)" | out-file -filepath $filename -append
      "  ------------ " | out-file -filepath $filename -append
      "   ID    = $($category.Id)" | out-file -filepath $filename -append
      "   Title = $($category.Title)" | out-file -filepath $filename -append
      "   #Subcategories =  $($category.GetSubcategories().Count)" | out-file -filepath $filename -append
      "   #Updates =  $($category.GetUpdates().Count)" | out-file -filepath $filename -append
      "" | out-file -filepath $filename -append
      $i++
    }
  }
}

trap
{
 "Error Occurred" | out-file -filepath $filename -append
 "Exception Message: "  | out-file -filepath $filename -append
 $_.Exception.Message | out-file -filepath $filename -append
 $_.Exception.StackTrace | out-file -filepath $filename -append
 exit
}

# EOF


