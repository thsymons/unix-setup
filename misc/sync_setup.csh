# Source this file to prepare for remote-to-local sync
set lpath = $PATH
set ppath = $PYTHONPATH
source /local/rapid/env/rapid.csh
setenv PATH $lpath
setenv PYTHONPATH $ppath
rehash
