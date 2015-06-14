
" Additions to verilog syntax

" Allows '%' command to toggle between begin-end pairs
" Note: requires following statement in user .vimrc
" source $VIMRUNTIME/macros/matchit.vim
let b:match_words = 
   \ '\<begin\>:\<end\>,' .
   \ '\<module\>:\<endmodule\>,' .
   \ '\<task\>:\<endtask\>,\<function\>:\<endfunction\>,' .
   \ '\<case\>:\<endcase\>,' .
   \ '\<class\>:\<endclass\>,' .
   \ '\<package\>:\<endpackage\>,' .
   \ '\<interface\>:\<endinterface\>,' .
   \ '\<program\>:\<endprogram\>,' .
   \ '\<generate\>:\<endgenerate\>,' .
   \ '`ifdef\>:`else\>:`endif\>,`ifndef\>:`else\>:\<endif\>,' .
   \ '`if\>:`else\>:`endif\>,'

" Highlights between begin-end code block pairs - doesn't work
syn region verilogBlock start=/\<begin\>/ end=/\<end\>/ contains=verilogBlock
