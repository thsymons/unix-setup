
setenv PATH ~/bin:$PATH
setenv TOOLS /import/rapid-tools
setenv PATH $TOOLS/scripts:$PATH
setenv VCS_HOME_PREFIX /tools/synopsys
setenv VCS_HOME /tools/synopsys/vcs/J-2014.12-1
setenv PATH ${PATH}:${VCS_HOME}/bin
setenv PATH /tools/synopsys/scl/linux64/bin:$PATH
setenv REPOS ssh://gato.us.oracle.com/import/rapid/repos
alias h history
alias go_mount 'sshfs gato:/import /export'
alias dpu_clone 'git clone $REPOS/dpu.git'
alias dirsize 'du -h -d 1'
alias work 'cd /import/pwa'
setenv DPU_SKIP_ARM_SETUP
setenv DPU_SKIP_CORESIGHT_SETUP
setenv DPU_SKIP_FORMAL_SETUP
setenv DPU_SKIP_VP_SETUP
setenv LAVA_ENVDIR
alias go_get 'rsync -avz -e ssh gato:\!*'

setenv LM_LICENSE_FILE /export/cadist-sme/license/keys/synopsys/synopsys_key
setenv SNPSLMD_LICENSE_FILE $LM_LICENSE_FILE
