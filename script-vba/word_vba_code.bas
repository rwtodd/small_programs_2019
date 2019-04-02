Sub ResetPara(p As Paragraph)
    ' Set the paragraph style based on clues to "Speaker"/"Transition"/"SceneTitle"
    Let stlSpk = ActiveDocument.Styles.Item("Speaker")
    Let stlTrn = ActiveDocument.Styles.Item("Transition")
    Let stlScn = ActiveDocument.Styles.Item("SceneTitle")
    If p.Range.Case = wdUpperCase Then
        Let txt = p.Range.Text
        If Left(txt, 4) = "INT." Or Left(txt, 4) = "EXT." Then
            p.Style = stlScn
        ElseIf Left(txt, 6) = "CUT TO" And Len(txt) <= 10 Then
            p.Style = stlTrn
        ElseIf Left(txt, 5) = "ANGLE" Then
            Rem it is a view angle direction, which I don't style.
        Else
            Rem it is a speaker...
            p.Style = stlSpk
        End If
    ElseIf InStr(LCase(Right(p.Range.Text, 15)), "(cont'd") <> 0 Then
        p.Style = stlSpk
    End If
End Sub

Sub DeleteBlanks()
    ' delete blank lines
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "^p^p"
        .Replacement.Text = "^p"
        .Forward = True
        .Wrap = wdFindStop
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
End Sub


Sub SetStyles()
  Let stlNormal = ActiveDocument.Styles.Item("Normal")
    
  Dim para As Paragraph
  For Each para In Selection.Paragraphs
    If para.Style = stlNormal Then
       Call ResetPara(para)
    End If
  Next para
End Sub

Sub MakeDialog(p As Paragraph)
    ' differentiate between dialog and stage directions, and
    ' set the paragraph style
    Let stlDia = ActiveDocument.Styles.Item("Dialog")
    Let stlStg = ActiveDocument.Styles.Item("StageDirs")
    
    Let trimmed = Trim(p.Range.Text)
    If Left(trimmed, 1) = "(" And Left(Right(trimmed, 2), 1) = ")" Then
        p.Style = stlStg
    Else
        p.Style = stlDia
    End If
End Sub

Function SelectCurPara() As Paragraph
    Selection.HomeKey Unit:=wdLine
    Selection.MoveRight Unit:=wdCharacter, Count:=1
    Selection.MoveUp Unit:=wdParagraph, Count:=1
    Set SelectCurPara = Selection.Paragraphs(1)
    SelectCurPara.Range.Select
End Function

Sub removeTrailingWS(p As Paragraph)
    p.Range.Select
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "^w^p"
        .Replacement.Text = "^p"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceOne
End Sub

Sub SlurpDialog()
    ' this is intended to be called by hotkey, to slurp a Normal paragraph
    ' into the current dialog
    Let stlNormal = ActiveDocument.Styles.Item("Normal")
    Dim p As Paragraph  ' the current Normal para
    Dim p1 As Paragraph ' the previous para
    Set p = SelectCurPara()
    Let First = True
    While p.Style <> stlNormal
        Set p = p.Next
        First = False
    Wend
    ' get rid of trailing spaces in p
    Call removeTrailingWS(p)
    Selection.SetRange Start:=p.Range.Start, End:=p.Range.Start
    Set p = SelectCurPara()
    If First Then
       Set p1 = p
    Else
       Set p1 = p.Previous
    End If
    
    ' set the style of p
    Call MakeDialog(p)
    If p.Range.Start <> p1.Range.Start Then
        ' ok now p = the current paragraph, and p1 is the previous one
        ' combine the paragraphs if their styles are the same...
        If p.Style = p1.Style Then
            Dim twoparas As Range
            Set twoparas = p1.Range
            twoparas.End = p.Range.End
            twoparas.Select
            With Selection.Find
                '.ClearFormatting
                '.Replacement.ClearFormatting
                .Text = "^p"
                .Replacement.Text = " "
                .Forward = True
                .Format = False
                .MatchCase = False
                .MatchWholeWord = False
                .MatchWildcards = False
                .MatchSoundsLike = False
                .MatchAllWordForms = False
            End With
            Selection.Find.Execute Replace:=wdReplaceOne
        End If
    End If
    ActiveDocument.ActiveWindow.ScrollIntoView ActiveDocument.Range(Selection.Range.Start, ActiveDocument.Range.End)
End Sub


Sub slurpWhileNormal()
    Let stlNormal = ActiveDocument.Styles.Item("Normal")
    
    ' keep slurping dialog until we hit the next speaker...
    Call SlurpDialog
    
    Dim p As Paragraph  ' the current Normal para
    Set p = SelectCurPara()
    Set p = p.Next
    While p.Style = stlNormal
        Call SlurpDialog
        Set p = SelectCurPara()
        Set p = p.Next
    Wend
End Sub

Sub SlurpUpOne()
    ' just like slurpDialog, only goes to the previous paragraph rather
    ' than the next one
    Let stlNormal = ActiveDocument.Styles.Item("Normal")
    Dim p As Paragraph  ' the current Normal para
    Dim p1 As Paragraph ' the next para
    Set p = SelectCurPara()
    
    Let First = True
    While p.Style <> stlNormal
      Set p = p.Previous
      First = False
    Wend
    
    ' get rid of trailing spaces in p
    Call removeTrailingWS(p)
    Selection.SetRange Start:=p.Range.Start, End:=p.Range.Start
    Set p = SelectCurPara()
    
    If First Then
       Set p1 = p
    Else
       Set p1 = p.Next
    End If
    
    ' set the style of p
    Call MakeDialog(p)
    If p.Range.Start <> p1.Range.Start Then
        ' ok now p = the current paragraph, and p1 is the next one
        ' combine the paragraphs if their styles are the same...
        If p.Style = p1.Style Then
            Dim twoparas As Range
            Set twoparas = p.Range
            twoparas.End = p1.Range.End
            twoparas.Select
            With Selection.Find
                '.ClearFormatting
                '.Replacement.ClearFormatting
                .Text = "^p"
                .Replacement.Text = " "
                .Forward = True
                .Format = False
                .MatchCase = False
                .MatchWholeWord = False
                .MatchWildcards = False
                .MatchSoundsLike = False
                .MatchAllWordForms = False
            End With
            Selection.Find.Execute Replace:=wdReplaceOne
        End If
    End If
    ActiveDocument.ActiveWindow.ScrollIntoView ActiveDocument.Range(Selection.Range.Start, ActiveDocument.Range.End)
End Sub

Sub SlurpUpWhileNormal()
    ' continues slurping previous paragraphs as long as the style is 'normal'
    Let stlNormal = ActiveDocument.Styles.Item("Normal")
    
    ' keep slurping dialog until we hit the next speaker...
    Call SlurpUpOne
    
    Dim p As Paragraph  ' the current Normal para
    Set p = SelectCurPara()
    Set p = p.Previous
    While p.Style = stlNormal
        Call SlurpUpOne
        Set p = SelectCurPara()
        Set p = p.Previous
    Wend
End Sub

