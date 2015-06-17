set lpath = $PATH
set ppath = $PYTHONPATH
set tools = $TOOLS
source /local/rapid/env/rapid.csh
setenv PATH $lpath
setenv PYTHONPATH $ppath
setenv VCS_HOME /tools/synopsys/vcs/J-2014.12-1
setenv UVM_HOME $VCS_HOME/etc/uvm
setenv PATH ${PATH}:${VCS_HOME}/bin
setenv TOOLS $tools
unsetenv SNPSLMD_LICENSE_FILE
unsetenv LD_LIBRARY_PATH
rehash
