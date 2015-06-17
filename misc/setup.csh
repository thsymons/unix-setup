# Source this file for simulation setup
setenv TOOLS /local/rapid-tools
setenv PATH $TOOLS/scripts:$PATH
set tools = $TOOLS
source /local/sync_setup.csh
setenv VCS_HOME_PREFIX /tools/synopsys
setenv VCS_HOME /tools/synopsys/vcs/J-2014.12-1
setenv UVM_HOME $VCS_HOME/etc/uvm
setenv PATH ${PATH}:${VCS_HOME}/bin
setenv TOOLS $tools
setenv REPOS ssh://gato.us.oracle.com/import/rapid/repos
unsetenv SNPSLMD_LICENSE_FILE
unsetenv LD_LIBRARY_PATH
rehash
