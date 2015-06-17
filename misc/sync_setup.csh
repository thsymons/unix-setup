# Source this file to prepare for remote-to-local sync
set lpath = $PATH
set ppath = $PYTHONPATH
if (! $?IMPORT_MOUNTED) then
  sshfs gato:/import /import
  setenv IMPORT_MOUNTED
endif
source /local/rapid/env/rapid.csh
setenv PATH $lpath
setenv PYTHONPATH $ppath
rehash
