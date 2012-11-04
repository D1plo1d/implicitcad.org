
wordlist = (str) ->
  obj = {}
  words = str.split " "
  obj[word] = true for word in words
  obj

CodeMirror.defineMIME "text/x-extopenscad",
  name: "clike"
  keywords: wordlist("circle for if else while module " + 
                  "circle square polygon " + 
                  "sphere cube cylinder " + 
                  "union difference intersection " + 
                  "translate scale rotate " + 
                  "linear_extrude rotate_extrude " +
                  "pack shell" )
  blockKeywords: wordlist "else for if module"
  atoms: wordlist "null true false" 

$ ->
  to_highlight = $(".highlightable")
  to_highlight.each (n) ->
     code = to_highlight[n].innerHTML
     to_highlight[n].innerHTML = ""
     cm = CodeMirror to_highlight[n], 
            value: code,
            mode: "text/x-extopenscad",
            readOnly: true


