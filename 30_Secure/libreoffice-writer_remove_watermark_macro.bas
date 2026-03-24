REM  *****  BASIC  *****
'  個人情報等文字列の削除
'  - ツールの準備(GUIツールなので以下のみでは足りないかもしれないので適宜追加等必要)
'    - `apt install libreoffice-writer`
'  - 削除
'    - 準備
'      - macroコードのsTarget(文字列)、aTarget(配列)のデータをそれぞれ自分のテキストに埋め込まれた文字に置き換える
'    - 個人情報などの文字列の削除
'      - `LibreOffice Writer`で複合化されたPDFを開く
'      - `LibreOffice WriterのTools -> Macros -> Edit Macros` を選択する
'      - 開いたMacroのModuel1のsub Mainルーチンの中に置き換え後の下記コードを挿入する
'      - F5キー等でMacroを起動する
'    - 確認
'      - 所望の結果になっているか確認し問題なければPDF等で出力する
Sub DeleteTextFrame()
    Dim oDoc As Object
    Dim oDrawPage As Object
    Dim oShape As Object
    Dim oText As Object
    Dim sText As String
    Dim i As Integer
    Dim j As Integer

    ' 削除したい文字を指定する
    Dim sTarget As String
    sTarget = "Licensed To: who <who@what_com> June 17, 2024"
    Dim aTarget As Variant
    aTarget = Array( _
    "Licensed To: who <who@what_com> June 17, 2024", _
    "96b680659a13e28ffab12536aadb1e94", _
    "<who@what_com>", _
    "25746910", _
    "Ryo Ito", _
    "ohNrhAfzA3YUEB7zYQeMv7asRrrC6mmK", _
    "live", _
    "© SANS Institute 2023")
    Dim leng As Integer
    leng = Len(sTarget)
    Dim countNow As Integer
    countNow = 0
    Dim mergedStr
    mergedStr = ""
    Dim ddd As Object
    Dim dddObject As Object
    Dim dddText As string
    Dim lastString As string
    Dim aIndex As Long
	Dim x As Integer
	Dim y As Integer
	Dim z As Integer
	x = 0
	y = 0
	z = 0
	aIndex = 0
    ' 現在のドキュメントを取得する
    oDoc = ThisComponent

    ' ドキュメントのページ数を取得する
    nPages = oDoc.getDrawPages().getCount()

    ' ページごとにループする
    For i = 0 To nPages - 1
        ' ページを取得する
        oDrawPage = oDoc.getDrawPages().getByIndex(i)

        ' ページの図形数を取得する
        nShapes = oDrawPage.getCount()

        ' 図形ごとにループする
        For j = nShapes - 1 To 0 Step -1
            ' 図形を取得する
            oShape = oDrawPage.getByIndex(j)

            ' 図形がテキストフレームであるか判定する
            If oShape.supportsService("com.sun.star.drawing.Text") Then
                ' テキストフレームのテキストを取得する
                oText = oShape.getText()
                sText = oText.getString()

                ' テキストに削除したい文字が含まれているか判定する

                For aIndex = LBound(aTarget) To UBound(aTarget)
	                If InStr(sText, aTarget(aIndex)) > 0 Then
    	                ' テキストフレームを削除する
        	            oDrawPage.remove(oShape)
            	    End If
                Next aIndex
                If leng > countNow Then
	                lastString = Mid(sTarget,leng - countNow, 1)
	            End If
                ' 比較する文字列の文字数をカウントする。一文字ずつ比較するため。
                If Len(sText) = 1 And sText = lastString Then
			        countNow = countNow + 1
			        mergedStr = sText + mergedStr
			        x = oDrawPage.getCount()
       			If countNow = leng Then
      				  	If StrComp(sTarget,mergedStr) = 0 Then
      				  		y = oDrawPage.getCount()
      				  		For k = x - 1 To oDrawPage.getCount() - leng Step -1
      				  			dddObject = oDrawPage.getByIndex(k)
 				  				ddd = dddObject.getText()
 				  				dddText = ddd.getString()
   				  				oDrawPage.remove(oDrawPage.getByIndex(k))
   				  				z = z + 1
   				  				If z = leng Then
   				  					Exit for
   				  				End If
      			  			Next k
			    	    End If
    	    	    End If
    	    	Else
    	    		countNow = 0
    	    		mergedStr = ""
    	    	End If
    	    End If
        Next j
    Next i
End Sub