```
git clone https://github.com/Kiborgik/aic8800dc-linux-patched.git
cd aic8800dc-linux-patched

sudo chmod +x install_setup.sh
sudo ./install_setup.sh

cd drivers/aic8800

sudo make

sudo make install
sudo depmod -a

sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv

lsmod | grep aic

sudo tee /etc/modules-load.d/aic8800.conf <<EOF
aic_load_fw
aic8800_fdrv
EOF
```
