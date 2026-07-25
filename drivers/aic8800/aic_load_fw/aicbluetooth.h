#ifndef _AICBLUETOOTH_H
#define _AICBLUETOOTH_H

typedef struct
{
    int8_t enable;
    int8_t dsss;
    int8_t ofdmlowrate_2g4;
    int8_t ofdm64qam_2g4;
    int8_t ofdm256qam_2g4;
    int8_t ofdm1024qam_2g4;
    int8_t ofdmlowrate_5g;
    int8_t ofdm64qam_5g;
    int8_t ofdm256qam_5g;
    int8_t ofdm1024qam_5g;
} txpwr_idx_conf_t;

typedef struct
{
    int8_t enable;
    int8_t chan_1_4;
    int8_t chan_5_9;
    int8_t chan_10_13;
    int8_t chan_36_64;
    int8_t chan_100_120;
    int8_t chan_122_140;
    int8_t chan_142_165;
} txpwr_ofst_conf_t;

typedef struct
{
    int8_t enable;
    int8_t xtal_cap;
    int8_t xtal_cap_fine;
} xtal_cap_conf_t;

int aic_bt_platform_init(struct aic_usb_dev *sdiodev);

void aic_bt_platform_deinit(struct aic_usb_dev *sdiodev);

int rwnx_plat_bin_fw_upload_android(struct aic_usb_dev *sdiodev, u32 fw_addr,
                               char *filename);

int rwnx_plat_m2d_flash_ota_android(struct aic_usb_dev *usbdev, char *filename);

int rwnx_plat_m2d_flash_ota_check(struct aic_usb_dev *usbdev, char *filename);

int rwnx_plat_bin_fw_patch_table_upload_android(struct aic_usb_dev *usbdev, char *filename);

int rwnx_plat_userconfig_upload_android(char *filename);

int8_t rwnx_atoi(char *value);
uint32_t rwnx_atoli(char *value);

void get_fw_path(char *fw_path);
void set_testmode(int val);
int get_testmode(void);
int get_hardware_info(void);

void get_userconfig_xtal_cap(xtal_cap_conf_t *xtal_cap);
void get_userconfig_txpwr_idx(txpwr_idx_conf_t *txpwr_idx);
void get_userconfig_txpwr_ofst(txpwr_ofst_conf_t *txpwr_ofst);

#endif
