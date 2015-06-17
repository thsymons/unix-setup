setenv PATH ~/bin:$PATH
setenv PATH ${PATH}:/local/rapid-tools/scripts
alias h history
alias dirsize 'du -h -d 1'
alias work 'cd /local/pwa'
alias go_mount 'sshfs gato:/import /import'
alias dpu_clone 'git clone $REPOS/dpu.git'
setenv DPU_SKIP_ARM_SETUP
setenv DPU_SKIP_CORESIGHT_SETUP
setenv DPU_SKIP_FORMAL_SETUP
setenv DPU_SKIP_VP_SETUP
setenv LAVA_ENVDIR
alias go_get 'rsync -avz -e ssh gato:\!*'
alias getctl 'gvim ~/.cshrc /local/setup.csh /local/sync_setup.csh /local/sync.list'

#setenv LM_LICENSE_FILE /import/cadist-sme/license/keys/synopsys/synopsys_key
#setenv SNPSLMD_LICENSE_FILE $LM_LICENSE_FILE
setenv SNPS_SIM_BC_CONFIG_FILE /local/rapid/env/synopsys_bc.setup
setenv PYTHONPATH

