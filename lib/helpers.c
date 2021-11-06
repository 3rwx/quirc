#include "helpers.h"

size_t quirc_code_size() {
    return sizeof(struct quirc_code);
}

size_t quirc_data_size() {
    return sizeof(struct quirc_data);
}

int quirc_data_get_version(struct quirc_data *data) {
    return data->version;
}

int quirc_data_get_ecc_level(struct quirc_data *data) {
    return data->ecc_level;
}

int quirc_data_get_mask(struct quirc_data *data) {
    return data->mask;
}

int quirc_data_get_data_type(struct quirc_data *data) {
    return data->data_type;
}

void *quirc_data_get_payload(struct quirc_data *data) {
    return data->payload;
}

int quirc_data_get_payload_len(struct quirc_data *data) {
    return data->payload_len;
}

uint32_t quirc_data_get_eci(struct quirc_data *data) {
    return data->eci;
}
