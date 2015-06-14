" Vim syntax file
" Language:	Verilog
" Maintainer:	Mun Johl <mun_johl@sierralogic.com>
" Last Update:  Fri Feb 15 10:22:27 PST 2002

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
   syntax clear
elseif exists("b:current_syntax")
   finish
endif

" Set the local value of the 'iskeyword' option
if version >= 600
   setlocal iskeyword=@,48-57,_,192-255,+,-,?
else
   set iskeyword=@,48-57,_,192-255,+,-,?
endif

" A bunch of useful SystemVerilog keywords : Missing from manual below
syn keyword systemVStatement  post_randomize rand randomize 
" A bunch of useful SystemVerilog keywords : From Accellera SV3.1a ref manual
syn keyword systemVStatement alias always always_comb always_ff always_latch and assert assign
syn keyword systemVStatement assume automatic before begin bind bins binsof bit
syn keyword systemVStatement break buf bufif0 bufif1 byte case casex casez
syn keyword systemVStatement cell chandle class clocking cmos config const constraint
syn keyword systemVStatement context continue cover covergroup coverpoint cross deassign default
syn keyword systemVStatement defparam design disable dist do edge else end
syn keyword systemVStatement endcase endclass endclocking endconfig endfunction endgenerate endgroup endinterface
syn keyword systemVStatement endmodule endpackage endprimitive endprogram endproperty endspecify endsequence endtable
syn keyword systemVStatement endtask enum event expect export extends extern final
syn keyword systemVStatement first_match for force foreach forever fork forkjoin function
syn keyword systemVStatement generate genvar highz0 highz1 if iff ifnone ignore_bins
syn keyword systemVStatement illegal_bins import incdir include initial inout input inside
syn keyword systemVStatement instance int integer interface intersect join join_any join_none
syn keyword systemVStatement large liblist library local localparam logic longint macromodule
syn keyword systemVStatement matches medium modport module nand negedge new nmos
syn keyword systemVStatement nor noshowcancelled not notif0 notif1 null or output
syn keyword systemVStatement package packed parameter pmos posedge primitive priority program
syn keyword systemVStatement property protected pull0 pull1 pulldown pullup pulsestyle_onevent pulsestyle_ondetect
syn keyword systemVStatement pure rand randc randcase randsequence rcmos real realtime
syn keyword systemVStatement ref reg release repeat return rnmos rpmos rtran
syn keyword systemVStatement rtranif0 rtranif1 scalared sequence shortint shortreal showcancelled signed
syn keyword systemVStatement small solve specify specparam static string strong0 strong1
syn keyword systemVStatement struct super supply0 supply1 table tagged task this
syn keyword systemVStatement throughout time timeprecision timeunit tran tranif0 tranif1 tri
syn keyword systemVStatement tri0 tri1 triand trior trireg type typedef union
syn keyword systemVStatement unique unsigned use var vectored virtual void wait
syn keyword systemVStatement wait_order wand weak0 weak1 while wildcard wire with
syn keyword systemVStatement within wor xnor xor 

syn keyword systemVStatement mailbox semaphore



syn keyword verilogLabel       begin end fork join
syn keyword verilogConditional if else case casex casez default endcase
syn keyword verilogRepeat      forever repeat while for

syn keyword verilogTodo contained TODO

syn match   verilogOperator "[&|~><!)(*#%@+/=?:;}{,.\^\-\[\]]"

syn region  verilogComment start="/\*" end="\*/" contains=verilogTodo
syn match   verilogComment "//.*" oneline contains=verilogTodo

syn match   verilogGlobal "`[a-zA-Z0-9_]\+\>"
syn match   verilogGlobal "$[a-zA-Z0-9_]\+\>"

syn match   verilogConstant "\<[A-Z][A-Z0-9_]\+\>"

syn match   verilogNumber "\(\<\d\+\|\)'[bB]\s*[0-1_xXzZ?]\+\>"
syn match   verilogNumber "\(\<\d\+\|\)'[oO]\s*[0-7_xXzZ?]\+\>"
syn match   verilogNumber "\(\<\d\+\|\)'[dD]\s*[0-9_xXzZ?]\+\>"
syn match   verilogNumber "\(\<\d\+\|\)'[hH]\s*[0-9a-fA-F_xXzZ?]\+\>"
syn match   verilogNumber "\<[+-]\=[0-9_]\+\(\.[0-9_]*\|\)\(e[0-9_]*\|\)\>"

syn region  verilogString start=+"+  end=+"+

" Directives
syn match   verilogDirective   "//\s*synopsys\>.*$"
syn region  verilogDirective   start="/\*\s*synopsys\>" end="\*/"
syn region  verilogDirective   start="//\s*synopsys dc_script_begin\>" end="//\s*synopsys dc_script_end\>"

syn match   verilogDirective   "//\s*\$s\>.*$"
syn region  verilogDirective   start="/\*\s*\$s\>" end="\*/"
syn region  verilogDirective   start="//\s*\$s dc_script_begin\>" end="//\s*\$s dc_script_end\>"

"Modify the following as needed.  The trade-off is performance versus
"functionality.
syn sync lines=50

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_verilog_syn_inits")
   if version < 508
      let did_verilog_syn_inits = 1
      command -nargs=+ HiLink hi link <args>
   else
      command -nargs=+ HiLink hi def link <args>
   endif

   " The default highlighting.
   HiLink verilogCharacter       Character
   HiLink verilogConditional     Conditional
   HiLink verilogRepeat          Repeat
   HiLink verilogString          String
   HiLink verilogTodo            Todo
   HiLink verilogComment         Comment
   HiLink verilogConstant        Constant
   HiLink verilogLabel           Label
   HiLink verilogNumber          Number
   HiLink verilogOperator        Special
   HiLink systemVStatement       Statement
   HiLink verilogGlobal          Define
   HiLink verilogDirective       SpecialComment

   delcommand HiLink
endif

let b:current_syntax = "verilog"

" vim: ts=8

