cd ../../oc-accel/software/tools/
sudo ./oc_maint -vvv
sudo ./snap_poke 0x10 0x2
cd  ../../../oc-utils-pr/oc-utils/
sudo ./oc-flash-script.sh hls_action_lowercase_oc_func_fw_afu_action_w_hls_action_0_pblock_1_partial.bin
sudo ./oc-reset.sh
