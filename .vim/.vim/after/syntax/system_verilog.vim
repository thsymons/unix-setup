"Additions to system_verilog syntax

syn keyword systemVStatement uint uint2 uint4 int2 int4 ulong long short ushort

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

