$application = New-Object -ComObject Visio.Application
$documents = $application.Documents
$document = $documents.Add("")


$pages = $application.ActiveDocument.Pages
$page = $pages.Item(1)
$page.PageSheet.CellsU("PlaceStyle")=17 # hierarchy, top to bottom
$page.PageSheet.CellsU("RouteStyle")=1 #
$page.PageSheet.CellsU("LineRouteExt")=2 #curved
$document.GestureFormatSheet.CellsU("Char.Font")=$document.Fonts.Item("Consolas").ID #font to consolas
$document.GestureFormatSheet.CellsU("Char.Size").FormulaU="8 pt"
$document.GestureFormatSheet.CellsU("Para.HorzAlign")=0 #alignleft



$s=Get-Content -encoding Unicode "$env:temp\asmcharttempfile.txt" -raw 
$blocks = $($s -split '(?m)(^\s*$)')
$i=0

#draw shapes
[System.Collections.ArrayList]$allshapes = @()
foreach ($block in $blocks){
if ($block.Length -gt 1){
    $newshape=$page.DrawRectangle(0+$i++,0,0,0)
    $newshape.Text=$block
    $($newshape.CellsU("Width")).FormulaU="GUARD(TEXTWIDTH(TheText))"
    $($newshape.CellsU("Height")).FormulaU="GUARD(TEXTHEIGHT(TheText,Width))"
 
    #color
    #color to calls
    foreach ($m in   $(Select-String "(?m-i)call    .*$" -InputObject $newshape.Text -AllMatches).Matches){
        $chr=$newshape.Characters
        $chr.Begin=$m.Index
        $chr.End=$m.Index+$m.length
        $chr.CharProps(1)=12
    }
    #color to branches
    foreach ($m in   $(Select-String "(?m-i)  Branch" -InputObject $newshape.Text -AllMatches).Matches){
        $chr=$newshape.Characters
        $chr.Begin=$m.Index
        $chr.End=$m.Index+$m.length
        $chr.CharProps(1)=4
    }
    #color to numbers
    foreach ($m in  $(Select-String "(?-im)([0-9A-F]+h)" -InputObject $newshape.Text -AllMatches).Matches){
        $chr=$newshape.Characters
        $chr.Begin=$m.Index
        $chr.End=$m.Index+$m.length
        $chr.CharProps(1)=9
    }

    $allshapes.Add($newshape) 
    }
}

#build connections
$i=0
foreach ($shape in $allshapes){
    $i++
    if (($shape.text -match "jmp     ") -or ($shape.text -match "ret\s$") -or ($shape.text -match "ret *[0-9A-F]*\s$")){ #for each block that do not jump or ret connect it with next shape
        "jumporret!"
    }
    else
    {
        $shape.AutoConnect($allshapes[$i],0)
        $page.Shapes[$page.Shapes.Count].CellsU("EndArrow")=4  #arrow               
    }

}


foreach ($shape in $allshapes){


    if ($shape.text -match    "(?m)(^.*Branch)"){ #for each block that has branch
        $branchline=$Matches[0]
        $branchaddress=$branchline.Substring($branchline.LastIndexOf('(')+1,$branchline.LastIndexOf(')')-$branchline.LastIndexOf('(')-1)
        $branchaddress
        #find connections
        foreach ($shape1 in $allshapes){
            if ($shape1.text -match   "(?m)(.)*$branchaddress "){ #finding corresponding block
                $shape.AutoConnect($shape1,0)
                $page.Shapes[$page.Shapes.Count].CellsU("LineColor")=4 #conditional connectors are blue
                $page.Shapes[$page.Shapes.Count].CellsU("EndArrow")=4  #arrow     
                break          
            }
        }

    }

}
$page.Layout()
$page.AutoSizeDrawing()

$application.visible = $true
