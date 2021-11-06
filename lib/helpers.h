#ifndef HELPERS_H_
#define HELPERS_H_

#include "quirc.h"

#ifdef __cplusplus
extern "C" {
#endif

size_t quirc_code_size();

size_t quirc_data_size();
int quirc_data_get_version(struct quirc_data *data);
int quirc_data_get_ecc_level(struct quirc_data *data);
int quirc_data_get_mask(struct quirc_data *data);
int quirc_data_get_data_type(struct quirc_data *data);
void *quirc_data_get_payload(struct quirc_data *data);
int quirc_data_get_payload_len(struct quirc_data *data);
uint32_t quirc_data_get_eci(struct quirc_data *data);

#ifdef __cplusplus
}
#endif

#endif
